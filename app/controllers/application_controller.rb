class ApplicationController < ActionController::Base
  include DfE::Analytics::Requests

  class UnredirectableError < StandardError; end

  before_action :set_sentry_user

  include Pagy::Backend

  helper_method :session_manager,
                :current_user,
                :authenticated?,
                :multi_role_user?,
                :single_role_user?

private

  # @return [Sessions::Users::DfEUser]
  # @return [Sessions::Users::AppropriateBodyUser]
  # @return [Sessions::Users::SchoolUser]
  # @return [Sessions::Users::DfEPersona]
  # @return [Sessions::Users::AppropriateBodyPersona]
  # @return [Sessions::Users::SchoolPersona]
  delegate :current_user, to: :session_manager

  # Used by Blazer
  # @see config/blazer.yml
  # @return [User, nil]
  delegate :user, to: :current_user, allow_nil: true

  # Used by Blazer to restrict access
  # @see config/blazer.yml
  # @return [String, nil]
  def require_admin
    redirect_to(sign_in_path) unless current_user&.dfe_user?
  end

  def authenticate
    return if authenticated?

    session_manager.requested_path = request.fullpath

    redirect_to(pre_login_redirect_path(request.fullpath))
  end

  # @return [Boolean]
  def authenticated?
    current_user.present?
  end

  # @return [Boolean]
  def multi_role_user?
    authenticated? && current_user.has_multiple_roles?
  end

  # @return [Boolean]
  def single_role_user?
    authenticated? && !current_user.has_multiple_roles?
  end

  # @return [String]
  def pre_login_redirect_path(requested_path)
    requested_path.start_with?("/admin") ? sign_in_path : root_path
  end

  # @return [String]
  # @raise [UnredirectableError]
  def post_login_redirect_path
    requested_path = session_manager.requested_path

    return requested_path if requested_path.present?
    return admin_path if current_user.dfe_user?
    return schools_ects_home_path if current_user.school_user?
    return ab_teachers_path if current_user.appropriate_body_user?

    fail(UnredirectableError)
  end

  # @return [Sessions::Manager]
  def session_manager
    @session_manager ||= Sessions::Manager.new(session, cookies)
  end

  def set_sentry_user
    Sentry.set_user(email: current_user&.email)
  end
end
