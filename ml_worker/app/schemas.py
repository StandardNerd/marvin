from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any

class TrainingConfiguration(BaseModel):
    lora_r: int = 16
    lora_alpha: int = 32
    lora_dropout: float = 0.05
    learning_rate: float = 2e-4
    epochs: int = 3
    batch_size: int = 4
    gradient_accumulation_steps: int = 4
    max_seq_length: int = 512
    quantization: str = "4bit"

class TrainingRequest(BaseModel):
    training_run_id: str
    base_model: str
    dataset_url: str
    configuration: TrainingConfiguration
    callback_url: Optional[str] = None

class TrainingStatus(BaseModel):
    training_run_id: str
    status: str
    current_step: Optional[int] = None
    current_epoch: Optional[float] = None
    current_loss: Optional[float] = None
    error_message: Optional[str] = None
    metrics: Optional[List[Dict[str, Any]]] = None

class EvaluationRequest(BaseModel):
    evaluation_id: str
    training_run_id: str
    base_model: str
    adapter_path: str
    eval_dataset_url: str
    callback_url: Optional[str] = None

class EvaluationResult(BaseModel):
    evaluation_id: str
    status: str
    metrics: Dict[str, Any] = Field(default_factory=dict)
    results: List[Dict[str, Any]] = Field(default_factory=list)
    error_message: Optional[str] = None

class HealthResponse(BaseModel):
    status: str
    gpu_available: bool
    gpu_name: Optional[str] = None
    active_jobs: int
