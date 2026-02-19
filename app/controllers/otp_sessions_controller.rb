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

    unless otp_access_allowed?
      @otp_form.errors.add(:base, "This account is not enabled for one time password sign in")
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

  def session_user
    return otp_school_user if otp_school_sign_in?

    Sessions::Users::DfEUser.new(email: otp_user.email)
  end

  def otp_school_sign_in?
    otp_school_sign_in_flag_enabled? && otp_user&.urn.present?
  end

  def otp_access_allowed?
    return false unless otp_user
    return true if internal_admin_email?

    if otp_school_sign_in_flag_enabled?
      otp_user.otp_school_urn.present?
    else
      false
    end
  end

  def internal_admin_email?
    domain = otp_user&.email.to_s.split("@", 2).last
    return false if domain.blank?

    INTERNAL_ADMIN_EMAIL_DOMAINS.include?(domain)
  end

  def otp_school_sign_in_flag_enabled?
    Rails.application.config.enable_otp_school_sign_in
  end

  def otp_school_user
    Sessions::Users::OTPSchoolUser.new(email: otp_user.email, name: otp_user.name, school_urn: otp_user.urn)
  end

  def otp_user
    @otp_user ||= @otp_form.user
  end
end
