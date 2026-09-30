# frozen_string_literal: true

# ML Worker configuration
Rails.application.config.ml_worker = ActiveSupport::OrderedOptions.new
Rails.application.config.ml_worker.url = ENV.fetch("ML_WORKER_URL", "http://localhost:8000")
Rails.application.config.ml_worker.api_key = ENV.fetch("ML_WORKER_API_KEY", "dev-worker-key")
Rails.application.config.ml_worker.timeout = ENV.fetch("ML_WORKER_TIMEOUT", 30).to_i

# Default base model
Rails.application.config.default_base_model = ENV.fetch("DEFAULT_BASE_MODEL", "Qwen/Qwen3-8B")

# Upload limits
Rails.application.config.max_upload_size = ENV.fetch("MAX_UPLOAD_SIZE", 524_288_000).to_i
