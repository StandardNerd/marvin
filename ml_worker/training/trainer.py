import os
import torch
import httpx
import tempfile
from datasets import load_dataset
from transformers import AutoTokenizer, AutoModelForCausalLM, BitsAndBytesConfig
from peft import LoraConfig, get_peft_model, prepare_model_for_kbit_training
from trl import SFTTrainer
from transformers import TrainingArguments

from app.schemas import TrainingConfiguration
from training.callbacks import MetricsCallback

class QLoRATrainer:
    def __init__(self, config: TrainingConfiguration, base_model: str, dataset_url: str, output_dir: str, callback_url: str = None):
        self.config = config
        self.base_model = base_model
        self.dataset_url = dataset_url
        self.output_dir = output_dir
        self.callback_url = callback_url
        self.metrics_callback = MetricsCallback(callback_url=self.callback_url)
        self.trainer = None

    def _download_dataset(self) -> str:
        response = httpx.get(self.dataset_url)
        response.raise_for_status()
        
        fd, path = tempfile.mkstemp(suffix=".jsonl")
        with os.fdopen(fd, 'w') as f:
            f.write(response.text)
        return path

    def train(self) -> dict:
        """Run QLoRA training. Returns final metrics."""
        dataset_path = self._download_dataset()
        dataset = load_dataset('json', data_files={'train': dataset_path})['train']

        # 1. Load tokenizer
        tokenizer = AutoTokenizer.from_pretrained(self.base_model, trust_remote_code=True)
        if tokenizer.pad_token is None:
            tokenizer.pad_token = tokenizer.eos_token

        # 2. Load model with BitsAndBytesConfig (4-bit NF4)
        bnb_config = BitsAndBytesConfig(
            load_in_4bit=True,
            bnb_4bit_quant_type='nf4',
            bnb_4bit_compute_dtype=torch.float16
        )

        model = AutoModelForCausalLM.from_pretrained(
            self.base_model,
            quantization_config=bnb_config,
            device_map="auto",
            trust_remote_code=True
        )
        
        # 3. Prepare model for kbit training
        model = prepare_model_for_kbit_training(model)

        # 4. Configure LoRA with PeftConfig
        peft_config = LoraConfig(
            r=self.config.lora_r,
            lora_alpha=self.config.lora_alpha,
            lora_dropout=self.config.lora_dropout,
            bias="none",
            task_type="CAUSAL_LM"
        )
        model = get_peft_model(model, peft_config)
        # 5. Format dataset with chat template
        def format_example(example):
            messages = example.get("messages", [])
            if hasattr(tokenizer, 'apply_chat_template'):
                try:
                    text = tokenizer.apply_chat_template(messages, tokenize=False, add_generation_prompt=False)
                except Exception:
                    # Fallback: simple formatting
                    text = "\n".join(f"{m.get('role', 'user')}: {m.get('content', '')}" for m in messages)
            else:
                text = "\n".join(f"{m.get('role', 'user')}: {m.get('content', '')}" for m in messages)
            return {"text": text}

        dataset = dataset.map(format_example)

        training_args = TrainingArguments(
            output_dir=self.output_dir,
            per_device_train_batch_size=self.config.batch_size,
            gradient_accumulation_steps=self.config.gradient_accumulation_steps,
            learning_rate=self.config.learning_rate,
            logging_steps=10,
            num_train_epochs=self.config.epochs,
            save_strategy="epoch",
            optim="paged_adamw_32bit",
            fp16=True,
            gradient_checkpointing=True,
            report_to="none"
        )

        # 6. Set up SFTTrainer from TRL
        self.trainer = SFTTrainer(
            model=model,
            train_dataset=dataset,
            dataset_text_field="text",
            max_seq_length=self.config.max_seq_length,
            tokenizer=tokenizer,
            args=training_args,
            callbacks=[self.metrics_callback]
        )

        # 7. Train
        self.trainer.train()
        
        # 8. Save adapter (NOT the full model)
        os.makedirs(self.output_dir, exist_ok=True)
        self.trainer.model.save_pretrained(self.output_dir)
        tokenizer.save_pretrained(self.output_dir)

        if os.path.exists(dataset_path):
            os.remove(dataset_path)

        # 9. Return metrics
        return {"metrics_history": self.metrics_callback.metrics_history}

    def cancel(self):
        """Signal the trainer to stop."""
        if self.metrics_callback:
            self.metrics_callback.should_stop = True
