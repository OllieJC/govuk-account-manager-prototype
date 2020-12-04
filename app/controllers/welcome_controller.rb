class WelcomeController < ApplicationController
  def show
    payload = ApplicationKey.validate_jwt!(params[:jwt]) if params[:jwt]

    redirect_to after_login_path(payload, current_user) and return if current_user
  end

protected

  def after_login_path(payload, user)
    payload&.dig(:post_login_oauth).presence || after_sign_in_path_for(user)
  end
end
