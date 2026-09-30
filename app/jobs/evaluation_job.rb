class EvaluationJob < ApplicationJob
  queue_as :default
  retry_on MlWorkerClient::ConnectionError, wait: 30.seconds, attempts: 3

  def perform(evaluation_id)
    evaluation = Evaluation.find(evaluation_id)
    logger.info "[Evaluation] Starting evaluation_id=#{evaluation_id}"

    return unless evaluation.status == 'pending'

    begin
      evaluation.update!(status: 'running')
      client = MlWorkerClient.new
      client.create_evaluation(evaluation)
      logger.info "[Evaluation] Submitted evaluation_id=#{evaluation_id}"

      # Poll for results
      EvaluationPollJob.set(wait: 30.seconds).perform_later(evaluation_id)
    rescue MlWorkerClient::Error => e
      evaluation.update!(
        status: 'failed',
        results: { error: "Failed to submit: #{e.message}" }
      )
      logger.error "[Evaluation] Failed evaluation_id=#{evaluation_id}: #{e.message}"
    end
  end
end
