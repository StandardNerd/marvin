class EvaluationPollJob < ApplicationJob
  queue_as :default

  def perform(evaluation_id)
    evaluation = Evaluation.find(evaluation_id)
    return unless evaluation.running?

    begin
      client = MlWorkerClient.new
      result = client.evaluation_status(evaluation_id.to_s)

      if result['status'] == 'completed'
        evaluation.update!(
          status: 'completed',
          metrics: result['metrics'],
          results: result['results']
        )
      elsif result['status'] == 'failed'
        evaluation.update!(
          status: 'failed',
          results: { error: result['error_message'] || 'Evaluation failed' }
        )
      else
        EvaluationPollJob.set(wait: 30.seconds).perform_later(evaluation_id)
      end
    rescue MlWorkerClient::ConnectionError
      EvaluationPollJob.set(wait: 1.minute).perform_later(evaluation_id)
    end
  end
end
