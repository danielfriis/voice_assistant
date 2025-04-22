class OauthCallbacksController < ApplicationController
  allow_unauthenticated_access

  def callback
    handle_oauth_callback
  end

  def failure
    redirect_to new_session_path, alert: "Authentication failed: #{params[:message]}"
  end

  private

  def handle_oauth_callback
    auth = request.env["omniauth.auth"]
    user = User.from_omniauth(auth)

    if user.persisted?
      start_new_session_for(user)
      redirect_to after_authentication_url
    else
      redirect_to new_session_path, alert: "Could not authenticate you. Please try again."
    end
  rescue => e
    Rails.logger.error "OAuth error: #{e.message}"
    redirect_to new_session_path, alert: "Authentication failed. Please try again."
  end
end
