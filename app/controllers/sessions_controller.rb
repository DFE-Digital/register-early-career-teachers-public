#
# 1. Sessions::Manager#begin_session! <- Sessions::Users::Builder#session_user
# 2. Sessions::Manager#current_user -> Sessions::User.from_session
#
class SessionsController < ApplicationController
  def new
    render :new
  end

  def create
    session_manager.begin_session!(session_user, id_token:)

    if authenticated?
      record_school_user_signs_in_event
      redirect_to post_login_redirect_path
    else
      session_manager.end_session!
      redirect_to sign_in_path
    end
  rescue Sessions::Users::Builder::UnknownOrganisation,
         Sessions::Users::Builder::UnknownPersonaType,
         Sessions::Users::Builder::UnknownProvider

    session[:invalid_user_organisation_name] = user_builder.organisation_name
    redirect_to access_denied_path
  end

  def destroy
    session_manager.end_session!
    redirect_to(root_path)
  end

  # Switches the current user session if they have multiple roles
  def update
    return unless authenticated?

    session_manager.switch_role!
    redirect_to post_login_redirect_path
  end

private

  delegate :id_token, to: :user_builder

  def record_school_user_signs_in_event
    return unless session_user.is_a?(Sessions::Users::SchoolUser)
    return unless session_user.school

    Events::Record.record_school_user_signs_in_event!(
      author: session_user,
      school: session_user.school
    )
  rescue StandardError => e # events should never block sign in
    Sentry.capture_exception(e)
  end

  def session_user
    @session_user ||= user_builder.session_user
  end

  # @return [Sessions::Users::Builder]
  def user_builder
    @user_builder ||= Sessions::Users::Builder.new(omniauth_payload: request.env["omniauth.auth"])
  end
end
