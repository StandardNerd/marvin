class TrainingRunCancelJob < ApplicationJob
  queue_as :default

  def perform(training_run_id)
    training_run = TrainingRun.find(training_run_id)

    return unless training_run.active?

    begin
      client = MlWorkerClient.new
      client.cancel_training_run(training_run_id.to_s)
      training_run.cancel!
      logger.info "[TrainingRun] Cancelled training_run_id=#{training_run_id}"
    rescue MlWorkerClient::Error => e
      logger.error "[TrainingRun] Failed to cancel training_run_id=#{training_run_id}: #{e.message}"
      # Cancel locally anyway
      training_run.cancel!
    end
  end
end
