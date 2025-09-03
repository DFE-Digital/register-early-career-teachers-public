class SessionsController < ApplicationController
  skip_before_action :authenticate

  def new
    render :new
  end

  def create
    session_manager.begin_session!(session_user, id_token:)

    if authenticated?
      redirect_to(post_login_redirect_path)
    else
      session_manager.end_session!
      redirect_to(sign_in_path)
    end
  end

  def destroy
    session_manager.end_session!
    redirect_to(root_path)
  end

private

  delegate :session_user, :id_token, to: :user_builder

  def user_builder
    @user_builder ||= Sessions::Users::Builder.new(omniauth_payload: request.env['omniauth.auth'])
  end
end
