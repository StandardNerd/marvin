class SessionsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:new, :create]
  layout 'auth'

  def new
    redirect_to projects_path if current_user
  end

  def create
    user = User.find_by(email: params[:email])
    if user&.authenticate(params[:password])
      session[:user_id] = user.id
      redirect_to projects_path, notice: 'Signed in successfully.'
    else
      flash.now[:alert] = 'Invalid email or password.'
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session.delete(:user_id)
    redirect_to login_path, notice: 'Signed out successfully.'
  end
end
