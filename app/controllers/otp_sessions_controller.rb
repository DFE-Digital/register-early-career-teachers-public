class OTPSessionsController < ApplicationController
  INTERNAL_ADMIN_EMAIL_DOMAINS = %w[
    education.gov.uk
    digital.education.gov.uk
  ].freeze

  before_action :build_otp_form, except: %i[new request_code]

  def new
    clean_up_session
    @otp_form = Sessions::OTPSignInForm.new
  end

  def create
    render :new and return unless @otp_form.valid?

    if @otp_form.user.present?
      @otp_form.generate_and_email_code_to_user!

      session["otp_email"] = @otp_form.email
    end

    redirect_to otp_sign_in_code_path
  end

  def request_code
    @otp_form = Sessions::OTPSignInForm.new(email: session["otp_email"])
  end

  def verify_code
    unless @otp_form.valid?(:verify)
      render :request_code and return
    end

    if otp_access_blocked?
      @otp_form.errors.add(:base, "This account is not enabled for migration testing")
      render :request_code and return
    end

    clean_up_session
    session_manager.begin_session!(session_user)

    if authenticated?
      redirect_to(post_login_redirect_path)
    else
      session_manager.end_session!
      redirect_to(otp_sign_in_path)
    end
  end

private

  def build_otp_form
    @otp_form = Sessions::OTPSignInForm.new(email:, code:)
  end

  def email
    permitted_params.fetch(:email, session["otp_email"])
  end

  def code
    permitted_params.fetch(:code, nil)
  end

  def clean_up_session
    session.delete("otp_email")
  end

  def permitted_params
    params.expect(sessions_otp_sign_in_form: %i[email code])
  end

  # TODO: Remove otp_school_user path after UR completes.
  def session_user
    return otp_school_user if migration_and_urn?

    Sessions::Users::DfEUser.new(email: otp_user.email)
  end

  def migration_and_urn?
    migration_testing_enabled? && otp_user&.urn.present?
  end

  def otp_access_blocked?
    return false unless migration_testing_enabled?
    return false if otp_user&.urn.present?
    return false if internal_admin_email?

    true
  end

  def internal_admin_email?
    domain = otp_user&.email.to_s.split("@", 2).last
    return false if domain.blank?

    INTERNAL_ADMIN_EMAIL_DOMAINS.include?(domain)
  end

  def migration_testing_enabled?
    Rails.env.migration? && Rails.application.config.enable_migration_testing
  end

  def otp_school_user
    Sessions::Users::OTPSchoolUser.new(email: otp_user.email, name: otp_user.name, school_urn: otp_user.urn)
  end

  def otp_user
    @otp_user ||= @otp_form.user
  end
end
