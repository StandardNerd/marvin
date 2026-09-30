class TrainingRunPollJob < ApplicationJob
  queue_as :default

  def perform(training_run_id)
    training_run = TrainingRun.find(training_run_id)

    return unless training_run.active?

    begin
      client = MlWorkerClient.new
      status = client.training_run_status(training_run_id.to_s)

      if status['status'] == 'completed'
        training_run.complete!
        logger.info "[TrainingRun] Completed training_run_id=#{training_run_id}"
      elsif status['status'] == 'failed'
        training_run.fail!(status['error_message'] || 'Training failed')
        logger.error "[TrainingRun] Failed training_run_id=#{training_run_id}"
      else
        # Store any new metrics
        if status['metrics'].present?
          status['metrics'].each do |metric|
            unless training_run.training_metrics.exists?(step: metric['step'])
              training_run.training_metrics.create!(
                step: metric['step'],
                epoch: metric['epoch'],
                loss: metric['loss'],
                learning_rate: metric['learning_rate'],
                raw_metrics: metric
              )
            end
          end
        end

        # Continue polling
        TrainingRunPollJob.set(wait: 30.seconds).perform_later(training_run_id)
      end
    rescue MlWorkerClient::ConnectionError => e
      logger.warn "[TrainingRun] Could not reach worker for training_run_id=#{training_run_id}: #{e.message}"
      # Retry polling later
      TrainingRunPollJob.set(wait: 1.minute).perform_later(training_run_id)
    end
  end
end
