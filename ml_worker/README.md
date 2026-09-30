# QLoRA Experiment Studio - ML Worker

This service is the backend worker for the QLoRA Experiment Studio. It handles model training (fine-tuning using QLoRA) and model evaluation workloads in background threads.

## Running Locally

1. Create a virtual environment and install dependencies:
   ```bash
   cd ml_worker
   python -m venv venv
   source venv/bin/activate
   pip install -r requirements.txt
   ```

2. Run the FastAPI application:
   ```bash
   uvicorn app.main:app --reload
   ```

## Environment Variables

- `ML_WORKER_API_KEY`: API Key for authentication (default: `dev-worker-key`)
- `ML_WORKER_PORT`: Port to run the service on
- `ML_WORKER_MODEL_STORAGE_PATH`: Path to store base models
- `ML_WORKER_ADAPTER_STORAGE_PATH`: Path to store LoRA adapters

## GPU Requirements

This worker requires a CUDA-compatible GPU to efficiently run QLoRA training and inference workloads.
