import os
import torch
import httpx
import tempfile
import difflib
import logging
from abc import ABC, abstractmethod
from datasets import load_dataset
from transformers import AutoTokenizer, AutoModelForCausalLM
from peft import PeftModel

logger = logging.getLogger(__name__)


class BaseEvaluator(ABC):
    """Abstract base class for evaluators. Extend this to add better evaluation methods."""

    @abstractmethod
    def evaluate(self) -> dict:
        """Run evaluation and return metrics and per-example results."""
        pass


class ModelEvaluator(BaseEvaluator):
    """
    Basic evaluation comparing base model + adapter against expected outputs.

    Uses exact match and simple text similarity (difflib.SequenceMatcher).
    These are basic evaluation metrics — they provide a rough comparison
    but are not comprehensive measures of LLM quality.
    """

    def __init__(self, base_model: str, adapter_path: str, eval_dataset_url: str):
        self.base_model = base_model
        self.adapter_path = adapter_path
        self.eval_dataset_url = eval_dataset_url

    def _download_dataset(self) -> str:
        response = httpx.get(self.eval_dataset_url)
        response.raise_for_status()

        fd, path = tempfile.mkstemp(suffix=".jsonl")
        with os.fdopen(fd, 'w') as f:
            f.write(response.text)
        return path

    def _extract_prompt_and_expected(self, item: dict) -> tuple:
        """Extract the user prompt and expected assistant response from a chat-format example."""
        messages = item.get("messages", [])
        if not messages:
            return item.get("prompt", ""), item.get("expected", "")

        # Build prompt from all messages except the last assistant message
        # The last assistant message is the expected output
        user_messages = []
        expected = ""
        for i, msg in enumerate(messages):
            role = msg.get("role", "")
            content = msg.get("content", "")
            if role == "assistant" and i == len(messages) - 1:
                expected = content
            else:
                user_messages.append(msg)

        return user_messages, expected

    def _format_prompt(self, messages: list, tokenizer) -> str:
        """Format messages into a prompt string using the tokenizer's chat template."""
        if hasattr(tokenizer, 'apply_chat_template') and isinstance(messages, list):
            try:
                return tokenizer.apply_chat_template(
                    messages, tokenize=False, add_generation_prompt=True
                )
            except Exception:
                pass
        # Fallback
        if isinstance(messages, list):
            return "\n".join(
                f"{m.get('role', 'user')}: {m.get('content', '')}" for m in messages
            ) + "\nassistant: "
        return str(messages)

    def evaluate(self) -> dict:
        dataset_path = self._download_dataset()
        dataset = load_dataset('json', data_files={'test': dataset_path})['test']

        tokenizer = AutoTokenizer.from_pretrained(self.base_model, trust_remote_code=True)
        if tokenizer.pad_token is None:
            tokenizer.pad_token = tokenizer.eos_token

        model = AutoModelForCausalLM.from_pretrained(
            self.base_model,
            device_map="auto",
            torch_dtype=torch.float16,
            trust_remote_code=True
        )
        model = PeftModel.from_pretrained(model, self.adapter_path)
        model.eval()

        results = []
        exact_matches = 0
        total_similarity = 0.0

        for item in dataset:
            prompt_messages, expected = self._extract_prompt_and_expected(item)
            if not expected:
                continue

            prompt_text = self._format_prompt(prompt_messages, tokenizer)

            inputs = tokenizer(prompt_text, return_tensors="pt", truncation=True, max_length=2048)
            inputs = {k: v.to(model.device) for k, v in inputs.items()}

            with torch.no_grad():
                outputs = model.generate(
                    **inputs,
                    max_new_tokens=256,
                    do_sample=False,
                    temperature=1.0,
                    pad_token_id=tokenizer.pad_token_id
                )

            generated_text = tokenizer.decode(outputs[0], skip_special_tokens=True)
            # Remove prompt from the beginning if present
            if generated_text.startswith(prompt_text):
                generated_completion = generated_text[len(prompt_text):].strip()
            else:
                generated_completion = generated_text.strip()

            exact_match = generated_completion.strip() == expected.strip()
            if exact_match:
                exact_matches += 1

            # Simple text similarity (no external NLP libs needed)
            similarity = difflib.SequenceMatcher(
                None, generated_completion.lower(), expected.lower()
            ).ratio()
            total_similarity += similarity

            # Build a readable input string for display
            if isinstance(prompt_messages, list):
                input_display = prompt_messages[-1].get("content", "") if prompt_messages else ""
            else:
                input_display = str(prompt_messages)[:200]

            results.append({
                "input": input_display,
                "expected": expected,
                "actual": generated_completion,
                "exact_match": exact_match,
                "similarity": round(similarity, 4)
            })

        total_examples = len(results)
        exact_match_rate = exact_matches / total_examples if total_examples > 0 else 0
        avg_similarity = total_similarity / total_examples if total_examples > 0 else 0
        aggregate_score = (exact_match_rate + avg_similarity) / 2

        metrics = {
            "exact_match": round(exact_match_rate, 4),
            "text_similarity": round(avg_similarity, 4),
            "aggregate_score": round(aggregate_score, 4),
            "total_examples": total_examples,
            "note": "Basic evaluation metrics. Not a comprehensive measure of LLM quality."
        }

        if os.path.exists(dataset_path):
            os.remove(dataset_path)

        logger.info(f"Evaluation complete: {total_examples} examples, "
                     f"exact_match={exact_match_rate:.3f}, similarity={avg_similarity:.3f}")

        return {
            "metrics": metrics,
            "results": results
        }
