class TrainingRunJob < ApplicationJob
  queue_as :default
  retry_on MlWorkerClient::ConnectionError, wait: 30.seconds, attempts: 5

  def perform(training_run_id)
    training_run = TrainingRun.find(training_run_id)
    logger.info "[TrainingRun] Submitting training_run_id=#{training_run_id} to ML worker"

    return unless training_run.status == 'queued'

    begin
      client = MlWorkerClient.new
      result = client.create_training_run(training_run)
      training_run.start!
      logger.info "[TrainingRun] Successfully submitted training_run_id=#{training_run_id}"

      # Schedule polling for status updates
      TrainingRunPollJob.set(wait: 30.seconds).perform_later(training_run_id)
    rescue MlWorkerClient::Error => e
      training_run.fail!("Failed to submit to ML worker: #{e.message}")
      logger.error "[TrainingRun] Failed to submit training_run_id=#{training_run_id}: #{e.message}"
    end
  end
end
