# frozen_string_literal: true

class MlWorkerClient
  class Error < StandardError; end
  class ConnectionError < Error; end
  class ApiError < Error; end

  def initialize
    @base_url = Rails.application.config.ml_worker.url
    @api_key = Rails.application.config.ml_worker.api_key
    @timeout = Rails.application.config.ml_worker.timeout
  end

  def health
    get('/health')
  end

  def create_training_run(training_run)
    dataset_url = build_dataset_url(training_run)
    callback_url = build_callback_url(training_run)

    post('/training-runs', {
      training_run_id: training_run.id.to_s,
      base_model: training_run.base_model,
      dataset_url: dataset_url,
      configuration: training_run.configuration,
      callback_url: callback_url
    })
  end

  def training_run_status(training_run_id)
    get("/training-runs/#{training_run_id}")
  end

  def cancel_training_run(training_run_id)
    post("/training-runs/#{training_run_id}/cancel", {})
  end

  def create_evaluation(evaluation)
    training_run = evaluation.training_run
    post('/evaluations', {
      evaluation_id: evaluation.id.to_s,
      training_run_id: training_run.id.to_s,
      base_model: training_run.base_model,
      adapter_path: adapter_path(training_run),
      eval_dataset_url: build_eval_dataset_url(evaluation),
      callback_url: build_eval_callback_url(evaluation)
    })
  end

  def evaluation_status(evaluation_id)
    get("/evaluations/#{evaluation_id}")
  end

  private

  def get(path)
    uri = URI.join(@base_url, path)
    request = Net::HTTP::Get.new(uri)
    request['X-API-Key'] = @api_key
    request['Content-Type'] = 'application/json'
    execute(uri, request)
  end

  def post(path, body)
    uri = URI.join(@base_url, path)
    request = Net::HTTP::Post.new(uri)
    request['X-API-Key'] = @api_key
    request['Content-Type'] = 'application/json'
    request.body = body.to_json
    execute(uri, request)
  end

  def execute(uri, request)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'
    http.open_timeout = @timeout
    http.read_timeout = @timeout

    response = http.request(request)

    case response
    when Net::HTTPSuccess
      JSON.parse(response.body)
    else
      raise ApiError, "Worker returned #{response.code}: #{response.body}"
    end
  rescue Errno::ECONNREFUSED, Errno::ECONNRESET, Net::OpenTimeout, Net::ReadTimeout => e
    raise ConnectionError, "Could not connect to ML worker: #{e.message}"
  end

  def build_dataset_url(training_run)
    # In production, this would be a URL the worker can download from.
    # For Docker Compose, we use the Rails service URL.
    rails_url = ENV.fetch('RAILS_INTERNAL_URL', 'http://localhost:3000')
    "#{rails_url}/api/v1/datasets/#{training_run.dataset_id}/export.jsonl"
  end

  def build_callback_url(training_run)
    rails_url = ENV.fetch('RAILS_INTERNAL_URL', 'http://localhost:3000')
    "#{rails_url}/api/v1/training_callbacks/#{training_run.id}"
  end

  def build_eval_dataset_url(evaluation)
    dataset = evaluation.training_run.dataset
    rails_url = ENV.fetch('RAILS_INTERNAL_URL', 'http://localhost:3000')
    "#{rails_url}/api/v1/datasets/#{dataset.id}/export.jsonl"
  end

  def build_eval_callback_url(evaluation)
    rails_url = ENV.fetch('RAILS_INTERNAL_URL', 'http://localhost:3000')
    "#{rails_url}/api/v1/evaluation_callbacks/#{evaluation.id}"
  end

  def adapter_path(training_run)
    "/app/storage/adapters/#{training_run.id}"
  end
end
