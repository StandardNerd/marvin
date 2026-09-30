module Api
  module V1
    class EvaluationCallbacksController < BaseController
      before_action :set_evaluation

      def complete
        @evaluation.update!(
          status: 'completed',
          metrics: params[:metrics],
          results: params[:results]
        )
        render json: { status: 'ok' }
      end

      def fail
        @evaluation.update!(
          status: 'failed',
          results: { error: params[:error_message] || 'Unknown error' }
        )
        render json: { status: 'ok' }
      end

      private

      def set_evaluation
        @evaluation = Evaluation.find(params[:id])
      end
    end
  end
end
