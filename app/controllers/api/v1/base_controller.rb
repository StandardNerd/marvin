module Api
  module V1
    class BaseController < ActionController::API
      before_action :authenticate_worker!

      private

      def authenticate_worker!
        api_key = request.headers['X-API-Key']
        expected = Rails.application.config.ml_worker.api_key
        unless api_key.present? && ActiveSupport::SecurityUtils.secure_compare(api_key, expected)
          render json: { error: 'Unauthorized' }, status: :unauthorized
        end
      end
    end
  end
end
