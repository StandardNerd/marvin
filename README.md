# QLoRA Experiment Studio

A self-hosted web application for managing LLM fine-tuning experiments using QLoRA (Quantized Low-Rank Adaptation). Built with Ruby on Rails for the web UI and a Python/FastAPI worker for GPU training.

## Overview

QLoRA Experiment Studio provides a complete workflow for fine-tuning language models:

```
Dataset → Curation → QLoRA Training → Evaluation → Adapter Registry
```

**Key features:**

- **Project management** — organize experiments by project with configurable base models
- **Dataset ingestion** — upload JSONL chat-format datasets with automatic validation
- **Dataset curation** — review, accept, reject, and edit individual training examples
- **QLoRA training** — configure and launch 4-bit quantized LoRA fine-tuning jobs
- **Live metrics** — monitor training loss, epoch progress, and learning rate in real-time
- **Evaluation** — compare fine-tuned adapters against base models with basic metrics
- **Experiment comparison** — side-by-side comparison of configurations and results
- **Model registry** — version and download LoRA adapter artifacts

## Quick Start

### With Docker Compose

```bash
docker compose up
```

Open [http://localhost:3000](http://localhost:3000) and sign up for an account.

### Local Development (without Docker)

**Prerequisites:**

- Ruby 3.4+ and Rails 8.1+
- Node.js 20+
- SQLite 3

```bash
# Install dependencies
bundle install

# Set up the database
rails db:create db:migrate

# Seed demo data
rails db:seed

# Start the development server
bin/dev
```

Open [http://localhost:3000](http://localhost:3000) and log in with:

```
Email:    demo@example.com
Password: password123
```

## Architecture

```
┌─────────────────┐     HTTP/JSON     ┌──────────────────┐
│                 │ ───────────────▶  │                  │
│   Rails App     │                   │  Python Worker   │
│   (Web UI)      │ ◀───────────────  │  (GPU Training)  │
│                 │    Callbacks       │                  │
└────────┬────────┘                   └────────┬─────────┘
         │                                     │
    ┌────▼────┐                          ┌─────▼─────┐
    │ SQLite  │                          │ GPU / CUDA │
    │ Storage │                          │ PyTorch    │
    └─────────┘                          └───────────┘
```

- **Rails** owns all domain data: projects, datasets, experiments, evaluations, and artifacts
- **Python worker** handles GPU-intensive training and evaluation
- Communication is via HTTP/JSON with API key authentication
- Rails never executes Python training code in its own process

## Technology Stack

### Rails Application

| Component | Technology |
|-----------|-----------|
| Framework | Ruby on Rails 8.1 |
| Database | SQLite |
| Frontend | Hotwire / Turbo / Stimulus |
| CSS | Tailwind CSS |
| Background Jobs | Solid Queue |
| File Storage | Active Storage |
| Authentication | has_secure_password (bcrypt) |
| Tests | Minitest |

### Python ML Worker

| Component | Technology |
|-----------|-----------|
| API Framework | FastAPI |
| ML Framework | PyTorch |
| Model Loading | Hugging Face Transformers |
| LoRA | PEFT |
| Training | TRL (SFTTrainer) |
| Quantization | bitsandbytes |

## Workflow

### 1. Create a Project

Each project targets a specific base model (e.g., `Qwen/Qwen3-8B`). All datasets, experiments, and adapters are organized within projects.

### 2. Upload a Dataset

Upload a JSONL file with chat-format training examples:

```json
{"messages":[{"role":"user","content":"How do I reset my password?"},{"role":"assistant","content":"Go to Settings > Password > Reset."}]}
{"messages":[{"role":"user","content":"What's your refund policy?"},{"role":"assistant","content":"We offer 30-day refunds on all plans."}]}
```

Each line is validated independently — invalid examples are flagged but don't block the entire dataset.

### 3. Curate Examples

Review each example in a chat-like interface. Accept, reject, edit, or delete examples. Use bulk actions for efficiency. Only accepted examples are used for training.

### 4. Configure and Launch Training

Create a QLoRA experiment with configurable parameters:

- **LoRA rank** (default: 16)
- **LoRA alpha** (default: 32)
- **Learning rate** (default: 2e-4)
- **Epochs** (default: 3)
- **Quantization** (default: 4-bit NF4)
- Batch size, gradient accumulation, max sequence length, dropout

Training runs asynchronously on the Python worker. The browser does not wait.

### 5. Monitor Training

View real-time training progress:

- Current epoch and step
- Training loss with a chart
- Learning rate schedule
- Elapsed time

### 6. Evaluate

Compare the fine-tuned adapter against the base model on evaluation examples. Basic metrics include exact match rate and text similarity.

> **Note:** These are basic evaluation metrics. They provide a rough comparison but are not comprehensive measures of LLM quality.

### 7. Register and Download Adapters

Register completed training runs as versioned adapter artifacts. Download the LoRA adapter weights for deployment or further experimentation.

## GPU Setup

The Rails application **does not require a GPU**. Only the Python ML worker needs GPU access for actual training.

### Requirements for Training

- NVIDIA GPU with CUDA support
- [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html) (for Docker)
- VRAM requirements depend on your configuration:
  - Base model size
  - Sequence length
  - Batch size
  - LoRA rank

### Enabling GPU in Docker Compose

Uncomment the GPU section in `docker-compose.yml`:

```yaml
ml-worker:
  deploy:
    resources:
      reservations:
        devices:
          - driver: nvidia
            count: 1
            capabilities: [gpu]
```

### Running the Worker Without Docker

```bash
cd ml_worker
pip install -r requirements.txt
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

## Environment Variables

Copy `.env.example` to `.env` and configure:

| Variable | Description | Default |
|----------|-------------|---------|
| `ML_WORKER_URL` | Python worker URL | `http://localhost:8000` |
| `ML_WORKER_API_KEY` | Shared API key for worker auth | `dev-worker-key` |
| `DEFAULT_BASE_MODEL` | Default Hugging Face model | `Qwen/Qwen3-8B` |
| `REDIS_URL` | Redis connection URL | `redis://localhost:6379/0` |
| `MAX_UPLOAD_SIZE` | Max dataset upload size (bytes) | `524288000` (500MB) |

## Development

### Running Tests

```bash
rails test
```

Tests do not require a GPU. The Python worker is mocked in Rails tests.

### Project Structure

```
├── app/
│   ├── controllers/          # Rails controllers
│   ├── jobs/                 # Background jobs
│   ├── models/               # Domain models
│   ├── services/             # Service objects (ML worker client)
│   ├── views/                # ERB templates
│   └── javascript/           # Stimulus controllers
├── config/                   # Rails configuration
├── db/                       # Migrations and seeds
├── ml_worker/                # Python ML worker
│   ├── app/                  # FastAPI application
│   ├── training/             # QLoRA training logic
│   ├── evaluation/           # Evaluation logic
│   ├── requirements.txt
│   └── Dockerfile
├── test/                     # Minitest tests
├── docker-compose.yml
└── .env.example
```

### Key Domain Models

- **Project** — top-level container, belongs to a user
- **Dataset** — uploaded JSONL file with validation status
- **DatasetExample** — individual training example with accept/reject state
- **TrainingRun** — QLoRA experiment with configuration and lifecycle
- **TrainingMetric** — per-step training metrics (loss, learning rate)
- **Evaluation** — comparison of base model vs. fine-tuned adapter
- **ModelArtifact** — versioned LoRA adapter in the model registry

### Background Jobs

| Job | Purpose |
|-----|---------|
| `DatasetProcessingJob` | Parse and validate uploaded JSONL files |
| `TrainingRunJob` | Submit training to the Python worker |
| `TrainingRunPollJob` | Poll worker for status updates |
| `TrainingRunCancelJob` | Cancel a running training job |
| `EvaluationJob` | Submit evaluation to the worker |
| `EvaluationPollJob` | Poll for evaluation results |

## Security

- All uploaded files are treated as untrusted input
- File types and sizes are validated
- User data is isolated — users can only access their own projects
- Rails ↔ Worker communication uses API key authentication
- Worker endpoints should not be exposed to the public internet
- No user-controlled input is interpolated into shell commands

## Demo Data

Running `rails db:seed` creates:

- A demo user (`demo@example.com` / `password123`)
- A sample project with a customer support dataset
- 25 example conversations with various accept/reject states
- A completed (fake) training run with simulated metrics
- A demo evaluation with basic scores
- A registered adapter artifact

**Note:** The demo training run does not represent a real trained model. It is synthetic data to demonstrate the UI.

## License

This project is provided as-is for development and experimentation purposes.
