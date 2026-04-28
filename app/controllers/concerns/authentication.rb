module Authentication
  extend ActiveSupport::Concern

  class UnredirectableError < StandardError; end

  included do
    helper_method :session_manager,
                  :current_user,
                  :authenticated?,
                  :multi_role_user?,
                  :single_role_user?

    # @return [Sessions::Users::DfEUser]
    # @return [Sessions::Users::AppropriateBodyUser]
    # @return [Sessions::Users::SchoolUser]
    # @return [Sessions::Users::DfEPersona]
    # @return [Sessions::Users::AppropriateBodyPersona]
    # @return [Sessions::Users::SchoolPersona]
    delegate :current_user, to: :session_manager
  end

private

  def authenticate
    Current.session = session["user_session"]
    Current.user = current_user

    if authenticated?
      Rails.logger.warn("authenticate: already authenticated!")
      return
    end

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

  # FIXME: path helpers bork for /admin/foo/bar
  # @return [String]
  def pre_login_redirect_path(requested_path)
    requested_path.start_with?("/admin") ? "/sign-in" : "/"
  end

  # @return [String]
  # @raise [UnredirectableError]
  def post_login_redirect_path
    requested_path = session_manager.requested_path
    Rails.logger.warn("post_login_redirect_path: current_user = #{current_user.email}")
    Rails.logger.warn("post_login_redirect_path: requested_path = #{requested_path}")

    case
    when requested_path.present?
      Rails.logger.warn("post_login_redirect_path: returning requested path")
      requested_path
    when current_user.dfe_user?
      Rails.logger.warn("post_login_redirect_path: returning admin path")
      admin_path
    when current_user.school_user?
      Rails.logger.warn("post_login_redirect_path: returning schools path")
      schools_ects_home_path
    when current_user.appropriate_body_user?
      Rails.logger.warn("post_login_redirect_path: returning ABs path")
      ab_teachers_path
    else
      fail(UnredirectableError)
    end
  end

  # @return [Sessions::Manager]
  def session_manager
    @session_manager ||= Sessions::Manager.new(session, cookies)
  end
end
