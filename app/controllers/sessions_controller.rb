class SessionsController < ApplicationController
  skip_before_action :authenticate

  def new
    render :new
  end

  def create
    session_manager.begin_session!(session_user)

    if authenticated?
      redirect_to(login_redirect_path)
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

  def session_user
    Sessions::Users::Builder.new(omniauth_payload: request.env['omniauth.auth'])
                            .session_user
  end
end
