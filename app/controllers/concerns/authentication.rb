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
    Current.session = session['user_session']
    Current.user = current_user

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

    case
    when requested_path.present? then requested_path
    when current_user.dfe_user? then admin_path
    when current_user.school_user? then schools_ects_home_path
    when current_user.appropriate_body_user? then ab_teachers_path
    else
      fail(UnredirectableError)
    end
  end

  # @return [Sessions::Manager]
  def session_manager
    @session_manager ||= Sessions::Manager.new(session, cookies)
  end
end
