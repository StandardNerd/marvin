class ApplicationController < ActionController::Base
  include Pagy::Backend

  before_action :authenticate_user!

  helper_method :current_user, :logged_in?

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def logged_in?
    current_user.present?
  end

  def authenticate_user!
    unless current_user
      redirect_to login_path, alert: 'Please sign in to continue.'
    end
  end
end
