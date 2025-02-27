class ApplicationController < ActionController::Base
  include DfE::Analytics::Requests

  class UnredirectableError < StandardError; end

  before_action :authenticate
  before_action :set_sentry_user

  include Pagy::Backend

  helper_method :current_user, :authenticated?, :session_manager

private

  # A type of Sessions::User
  delegate :current_user, to: :session_manager

  # The User model instance associated to the current session user (Sessions::User)
  # Used by Blazer. See config/blazer.yml
  delegate :user, to: :current_user, allow_nil: true

  # This method is used by Blazer to restrict access. See config/blazer.yml
  def require_admin
    redirect_to(sign_in_path) unless Admin::Access.new(current_user).can_access?
  end

  def ab_home_path
    ab_teachers_path if current_user.appropriate_body_user?
  end

  def school_home_path
    schools_ects_home_path if current_user.school_user?
  end

  def admin_home_path
    admin_path if current_user&.dfe_user?
  end

  def authenticate
    return if authenticated?

    session_manager.requested_path = request.fullpath
    redirect_to(sign_in_path)
  end

  def authenticated?
    current_user.present?
  end

  def login_redirect_path
    session_manager.requested_path || admin_home_path || ab_home_path || school_home_path || fail(UnredirectableError)
  end

  def session_manager
    @session_manager ||= Sessions::Manager.new(session, cookies)
  end

  def set_sentry_user
    Sentry.set_user(email: current_user&.email)
  end
end
