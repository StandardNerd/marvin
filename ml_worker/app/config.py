from pydantic_settings import BaseSettings
from typing import Optional
import os

class Settings(BaseSettings):
    host: str = "0.0.0.0"
    port: int = 8000
    api_key: str = "dev-worker-key"
    rails_url: str = "http://rails:3000"
    model_storage_path: str = "/app/storage/models"
    adapter_storage_path: str = "/app/storage/adapters"
    max_concurrent_jobs: int = 1
    log_level: str = "INFO"
    
    class Config:
        env_prefix = "ML_WORKER_"

settings = Settings()
