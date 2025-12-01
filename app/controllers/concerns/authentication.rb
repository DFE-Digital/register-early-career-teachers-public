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

  # FIXME: path helpers bork for /admin/foo/bar
  # @return [String]
  def pre_login_redirect_path(requested_path)
    requested_path.start_with?("/admin") ? "/sign-in" : "/"
  end

  # @return [String]
  # @raise [UnredirectableError]
  def post_login_redirect_path
    requested_path = session_manager.requested_path

    case
    when requested_path.present? then requested_path
    when induction_information_needs_update? then induction_tutor_wizard_path
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

  def induction_information_needs_update?
    return unless current_user.school_user?
    return if current_user.dfe_user_impersonating_school_user?
    return if multi_role_user?
    return unless current_user.school

    induction_tutor_updated_in.blank? || induction_tutor_updated_in.year < current_contract_year
  end

  # TODO: A subsequent PR will check whether the induction tutor details are present
  # If they are not we'll probably redirect to a different wizard
  def induction_tutor_wizard_path
    schools_confirm_existing_induction_tutor_wizard_edit_path
  end

  def current_contract_year
    ContractPeriod.containing_date(Time.zone.today).year
  end

  def induction_tutor_updated_in
    current_user.school.induction_tutor_last_nominated_in_year
  end
end
