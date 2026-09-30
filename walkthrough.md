# QLoRA Experiment Studio: Complete Walkthrough Guide

This walkthrough guides you through setting up, navigating, and testing the **QLoRA Experiment Studio** application from end to end.

---

## 1. Quick Start & Setup

You can run the application either with **Docker Compose** or directly on your machine in **Local Development** mode.

### Option A: Local Development (Fastest for testing)

1. **Install dependencies:**
   ```bash
   bundle install
   ```

2. **Database setup and seed demo data:**
   ```bash
   rails db:create db:migrate
   rails db:seed
   ```

3. **Compile Tailwind CSS:**
   ```bash
   rails tailwindcss:build
   ```

4. **Start the Rails development server:**
   ```bash
   bin/dev
   # or: rails server -p 3000
   ```

5. **(Optional) Start the Python ML Worker:**
   ```bash
   cd ml_worker
   python3 -m venv venv && source venv/bin/activate
   pip install -r requirements.txt
   uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
   ```

### Option B: Docker Compose

```bash
docker compose up --build
```
*Note: To attach NVIDIA GPUs to the worker, uncomment the `deploy.resources.reservations.devices` block in `docker-compose.yml`.*

---

## 2. Default Credentials & Seed State

The database seed provides ready-to-explore demo data:

- **Login URL:** [http://localhost:3000/login](http://localhost:3000/login)
- **Email:** `demo@example.com`
- **Password:** `password123`

### Pre-loaded Resources:
- **Projects:**
  1. `Customer Support Bot` (Base Model: `Qwen/Qwen3-8B`)
  2. `Code Review Assistant` (Base Model: `Qwen/Qwen3-8B`)
- **Dataset:** `support-conversations-v1` containing 25 realistic multi-turn support interactions.
- **Experiment:** `support-qlora-v1 (demo)` with 75 simulated training loss steps and completed status.
- **Evaluation:** `Evaluation - Demo` with exact match and text similarity scores.
- **Model Artifact:** `support-assistant v1` registered in the registry.

---

## 3. End-to-End Workflow Tour

The application implements a six-stage workflow:

```
[Project] ➔ [Dataset Upload] ➔ [Curation] ➔ [QLoRA Training] ➔ [Evaluation] ➔ [Adapter Registry]
```

### Stage 1: Authentication & Navigation
1. Navigate to `/login`.
2. Enter `demo@example.com` / `password123`.
3. Notice the dark developer-focused theme, high-contrast badges, and clean top navigation:
   - **Projects:** View all active projects and summary metrics.
   - **Experiments:** Global experiment list and multi-run comparison tool.

### Stage 2: Managing Projects
1. Visit the Projects dashboard (`/projects`).
2. Click **New Project** (`/projects/new`).
3. Enter:
   - **Name:** `Legal Assistant QLoRA`
   - **Description:** `Fine-tuning Qwen for legal contract question-answering`
   - **Base Model:** `Qwen/Qwen3-8B` (or `meta-llama/Llama-2-7b-hf`)
4. Click **Create Project**. You are redirected to the project detail page showing:
   - Base model tag.
   - Datasets table (empty).
   - Experiments table (empty).

### Stage 3: Dataset Ingestion & Validation
1. From the project show page, click **Upload Dataset**.
2. Form fields:
   - **Name:** `contract-qa-v1`
   - **Description:** `Clause extraction conversation pairs`
   - **File (JSONL):** Select a `.jsonl` file.

   *Sample JSONL format for testing:*
   ```json
   {"messages":[{"role":"user","content":"What is the governing law in clause 4?"},{"role":"assistant","content":"Clause 4 states the contract is governed by the laws of California."}]}
   {"messages":[{"role":"user","content":"Is there an indemnity cap?"},{"role":"assistant","content":"Yes, indemnity is capped at 12 months of paid fees."}]}
   ```
3. Submit the upload. Active Storage stores the raw file and triggers `DatasetProcessingJob`.
4. The background job validates:
   - Valid JSON syntax.
   - Presence of an array of `messages`.
   - Valid roles (`system`, `user`, `assistant`).
   - At least one `user` and one `assistant` message per item.
5. Each line becomes a `DatasetExample`. Any invalid line records validation errors without failing the entire dataset.

### Stage 4: Dataset Curation
1. Open any dataset (e.g. `support-conversations-v1`).
2. **Review Metrics:** Top cards show Total, Accepted, Rejected, Needs Review, and Errors count.
3. **Filter Examples:** Use tabs to switch between `All`, `Accepted`, `Rejected`, `Needs Review`, and `Errors`.
4. **Chat-Style Display:** Conversations are rendered with distinct user (`U`) and assistant (`A`) bubbles.
5. **Interactive Actions:**
   - Click **Accept** or **Reject** on individual items.
   - Click **Edit** to modify the JSON messages if typo fixing or redaction is needed.
   - Use the **Select All** checkbox to bulk **Accept Selected**, **Reject Selected**, or **Delete Selected**.

### Stage 5: Configuring & Launching a QLoRA Experiment
1. From the dataset or project view, click **New Experiment**.
2. Fill in:
   - **Name:** `support-qlora-v2`
   - **Dataset:** Select `support-conversations-v1` (displays accepted example count).
   - **Base Model:** Pre-populated from project (`Qwen/Qwen3-8B`).
3. Expand **QLoRA Configuration**:
   - `LoRA Rank (r)`: `16`
   - `LoRA Alpha`: `32`
   - `LoRA Dropout`: `0.05`
   - `Learning Rate`: `0.0002`
   - `Epochs`: `3`
   - `Batch Size`: `1`
   - `Gradient Accumulation Steps`: `8`
   - `Max Sequence Length`: `2048`
   - `Quantization`: `4bit_nf4 (recommended)` (or `4bit_fp4`, `8bit`)
4. Click **Create Experiment**. The experiment is saved in `pending` status.
5. Click **Start Training**:
   - Status updates to `queued`.
   - `TrainingRunJob` initiates an HTTP request to the Python ML worker at `/training-runs`.
   - The worker starts the job in a background thread and transitions the state to `running`.

### Stage 6: Live Training Dashboard
1. The experiment page automatically polls (`data-controller="polling"`) for live updates.
2. The dashboard displays:
   - **Current Step** and **Current Epoch**.
   - **Current Loss** value.
   - **Real-time Canvas Loss Chart** (`chart_controller.js`) plotting step vs loss.
   - Run duration counter.
   - **Cancel Training** button for active runs.

### Stage 7: Evaluation & Comparison
1. When training finishes (status `completed`):
   - Click **Run Evaluation** (`/projects/:id/training_runs/:id/evaluations/new`).
   - The worker executes evaluation against test examples, computing:
     - Exact Match Rate
     - Text Similarity (difflib SequenceMatcher)
     - Aggregate Score
   - Results clearly display the note: *"These are basic evaluation metrics. Not a comprehensive measure of LLM quality."*
2. Navigate to **Experiments** in top nav:
   - Select multiple experiment checkboxes.
   - Click **Compare Experiments**.
   - The comparison matrix highlights hyperparameter differences (e.g. rank, learning rate) with visual diff tags and compares loss and evaluation scores side-by-side.

### Stage 8: Adapter Artifact Registry & Download
1. On a completed experiment, click **Register Adapter**:
   - Name: `customer-support-lora`
   - Version: Auto-generated `v1` (or `v2`)
   - Description: Release notes.
2. The adapter is registered under the project's **Model Registry**.
3. Click **Download Adapter** to download the adapter artifact directly via Active Storage.

---

## 4. Verification Criteria (VEC) Documents

A structured verification suite has been created to rigorously test each subsystem of the application:

| Document | Verification Area | Target Components |
|---|---|---|
| [`vec001.md`](file:///Users/jono/projects/github/marvin/vec001.md) | **Environment, Boot & Health** | Docker Compose, Rails boot, ML Worker health, DB schema |
| [`vec002.md`](file:///Users/jono/projects/github/marvin/vec002.md) | **Authentication, Security & Isolation** | User signup/login, multi-tenant isolation, worker API key |
| [`vec003.md`](file:///Users/jono/projects/github/marvin/vec003.md) | **Projects & Base Model Management** | Project CRUD, validations, base model configuration |
| [`vec004.md`](file:///Users/jono/projects/github/marvin/vec004.md) | **Dataset Ingestion & Validation** | Active Storage upload, JSONL parsing, format validation |
| [`vec005.md`](file:///Users/jono/projects/github/marvin/vec005.md) | **Dataset Curation & Bulk Actions** | Curation UI, chat bubbles, filtering, bulk accept/reject |
| [`vec006.md`](file:///Users/jono/projects/github/marvin/vec006.md) | **QLoRA Configuration & Submission** | Hyperparameters, immutability, worker HTTP payload |
| [`vec007.md`](file:///Users/jono/projects/github/marvin/vec007.md) | **Training Lifecycle & Live Metrics** | Status transitions, canvas chart, polling, cancellation |
| [`vec008.md`](file:///Users/jono/projects/github/marvin/vec008.md) | **Evaluation & Experiment Comparison** | Basic evaluation metrics, side-by-side config diff table |
| [`vec009.md`](file:///Users/jono/projects/github/marvin/vec009.md) | **Model Registry & Adapter Distribution**| Model artifact registration, versioning, file downloads |
| [`vec010.md`](file:///Users/jono/projects/github/marvin/vec010.md) | **Automated Test Suite & Persistence** | 77 passing Minitest cases, restart data durability |

---

## 5. Automated Test Suite Execution

To verify all test cases locally without requiring a GPU:

```bash
rails test
```

Expected result:
```text
Running 77 tests in parallel using 8 processes
77 runs, 128 assertions, 0 failures, 0 errors, 0 skips
```
