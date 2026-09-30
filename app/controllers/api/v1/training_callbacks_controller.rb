module Api
  module V1
    class TrainingCallbacksController < BaseController
      before_action :set_training_run

      def update
        status = params[:status]
        if TrainingRun::VALID_STATUSES.include?(status)
          @training_run.update!(status: status)
          if status == 'running' && @training_run.started_at.nil?
            @training_run.update!(started_at: Time.current)
          end
          render json: { status: 'ok' }
        else
          render json: { error: 'Invalid status' }, status: :unprocessable_entity
        end
      end

      def metrics
        metric_params = params.permit(:step, :epoch, :loss, :learning_rate, raw_metrics: {})
        @training_run.training_metrics.create!(metric_params)
        # Update summary metrics on the training run
        @training_run.update!(metrics: {
          'latest_step' => metric_params[:step],
          'latest_epoch' => metric_params[:epoch],
          'latest_loss' => metric_params[:loss]
        })
        render json: { status: 'ok' }
      end

      def complete
        @training_run.complete!
        render json: { status: 'ok' }
      end

      def fail
        @training_run.fail!(params[:error_message] || 'Unknown error')
        render json: { status: 'ok' }
      end

      private

      def set_training_run
        @training_run = TrainingRun.find(params[:id])
      end
    end
  end
end
