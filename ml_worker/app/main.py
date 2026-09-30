import os
import torch
import logging
import threading
import httpx
from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from typing import Dict, Any

from app.config import settings
from app.auth import get_api_key
from app.schemas import (
    TrainingRequest, TrainingStatus, 
    EvaluationRequest, EvaluationResult, HealthResponse
)
from training.trainer import QLoRATrainer
from evaluation.evaluator import ModelEvaluator

logging.basicConfig(level=settings.log_level)
logger = logging.getLogger(__name__)

app = FastAPI(title="QLoRA Experiment Studio - ML Worker")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# In-memory stores
active_trainings: Dict[str, Dict[str, Any]] = {}
active_evaluations: Dict[str, Dict[str, Any]] = {}

def run_training_job(run_id: str, request: TrainingRequest):
    active_trainings[run_id]["status"] = "running"
    output_dir = os.path.join(settings.adapter_storage_path, run_id)
    
    try:
        trainer = QLoRATrainer(
            config=request.configuration,
            base_model=request.base_model,
            dataset_url=request.dataset_url,
            output_dir=output_dir,
            callback_url=request.callback_url
        )
        active_trainings[run_id]["trainer"] = trainer
        
        result = trainer.train()
        
        active_trainings[run_id]["status"] = "completed"
        active_trainings[run_id]["metrics"] = result.get("metrics_history", [])
    except Exception as e:
        logger.error(f"Training failed: {e}")
        active_trainings[run_id]["status"] = "failed"
        active_trainings[run_id]["error_message"] = str(e)
    finally:
        if "trainer" in active_trainings[run_id]:
            del active_trainings[run_id]["trainer"]
        
        if request.callback_url:
            try:
                with httpx.Client() as client:
                    client.post(request.callback_url, json={"training_run_id": run_id, "status": active_trainings[run_id]["status"]}, timeout=5.0)
            except Exception:
                pass

def run_evaluation_job(eval_id: str, request: EvaluationRequest):
    active_evaluations[eval_id]["status"] = "running"
    
    try:
        evaluator = ModelEvaluator(
            base_model=request.base_model,
            adapter_path=request.adapter_path,
            eval_dataset_url=request.eval_dataset_url
        )
        result = evaluator.evaluate()
        
        active_evaluations[eval_id]["status"] = "completed"
        active_evaluations[eval_id]["metrics"] = result["metrics"]
        active_evaluations[eval_id]["results"] = result["results"]
    except Exception as e:
        logger.error(f"Evaluation failed: {e}")
        active_evaluations[eval_id]["status"] = "failed"
        active_evaluations[eval_id]["error_message"] = str(e)
    finally:
        if request.callback_url:
            try:
                with httpx.Client() as client:
                    client.post(request.callback_url, json={"evaluation_id": eval_id, "status": active_evaluations[eval_id]["status"]}, timeout=5.0)
            except Exception:
                pass

@app.get("/health", response_model=HealthResponse)
def health_check():
    gpu_available = torch.cuda.is_available()
    gpu_name = torch.cuda.get_device_name(0) if gpu_available else None
    active_jobs = len([j for j in active_trainings.values() if j.get("status") == "running"]) + \
                  len([j for j in active_evaluations.values() if j.get("status") == "running"])
    
    return HealthResponse(
        status="ok",
        gpu_available=gpu_available,
        gpu_name=gpu_name,
        active_jobs=active_jobs
    )

@app.post("/training-runs", response_model=TrainingStatus, dependencies=[Depends(get_api_key)])
def start_training(request: TrainingRequest):
    run_id = request.training_run_id
    if run_id in active_trainings and active_trainings[run_id]["status"] == "running":
        raise HTTPException(status_code=400, detail="Training already running")
        
    active_trainings[run_id] = {
        "training_run_id": run_id,
        "status": "pending",
        "error_message": None,
        "metrics": []
    }
    
    thread = threading.Thread(target=run_training_job, args=(run_id, request))
    thread.start()
    
    return TrainingStatus(**active_trainings[run_id])

@app.get("/training-runs/{training_run_id}", response_model=TrainingStatus, dependencies=[Depends(get_api_key)])
def get_training_status(training_run_id: str):
    if training_run_id not in active_trainings:
        raise HTTPException(status_code=404, detail="Training run not found")
        
    job = active_trainings[training_run_id]
    
    current_step = None
    current_epoch = None
    current_loss = None
    
    if "trainer" in job and job["trainer"].metrics_callback.metrics_history:
        last_metric = job["trainer"].metrics_callback.metrics_history[-1]
        current_step = last_metric.get("step")
        current_epoch = last_metric.get("epoch")
        current_loss = last_metric.get("loss")
        
    return TrainingStatus(
        training_run_id=training_run_id,
        status=job["status"],
        current_step=current_step,
        current_epoch=current_epoch,
        current_loss=current_loss,
        error_message=job.get("error_message"),
        metrics=job.get("metrics", [])
    )

@app.post("/training-runs/{training_run_id}/cancel", dependencies=[Depends(get_api_key)])
def cancel_training(training_run_id: str):
    if training_run_id not in active_trainings:
        raise HTTPException(status_code=404, detail="Training run not found")
        
    job = active_trainings[training_run_id]
    if job["status"] != "running":
        raise HTTPException(status_code=400, detail="Training is not running")
        
    if "trainer" in job:
        job["trainer"].cancel()
        job["status"] = "cancelled"
        
    return {"status": "cancelled"}

@app.post("/evaluations", response_model=EvaluationResult, dependencies=[Depends(get_api_key)])
def start_evaluation(request: EvaluationRequest):
    eval_id = request.evaluation_id
    if eval_id in active_evaluations and active_evaluations[eval_id]["status"] == "running":
        raise HTTPException(status_code=400, detail="Evaluation already running")
        
    active_evaluations[eval_id] = {
        "evaluation_id": eval_id,
        "status": "pending",
        "metrics": {},
        "results": [],
        "error_message": None
    }
    
    thread = threading.Thread(target=run_evaluation_job, args=(eval_id, request))
    thread.start()
    
    return EvaluationResult(**active_evaluations[eval_id])

@app.get("/evaluations/{evaluation_id}", response_model=EvaluationResult, dependencies=[Depends(get_api_key)])
def get_evaluation_status(evaluation_id: str):
    if evaluation_id not in active_evaluations:
        raise HTTPException(status_code=404, detail="Evaluation not found")
        
    return EvaluationResult(**active_evaluations[evaluation_id])
