class OTPSessionsController < ApplicationController
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
    if @otp_form.valid?(:verify)
      clean_up_session

      session_manager.begin_session!(session_user)

      if authenticated?
        redirect_to(post_login_redirect_path)
      else
        session_manager.end_session!
        redirect_to(otp_sign_in_path)
      end
    else
      render :request_code
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

    Sessions::Users::DfEUser.new(email: @otp_form.email)
  end

  def migration_and_urn?
    Rails.application.config.enable_migration_testing && Rails.env.migration? && otp_user&.urn.present?
  end

  def otp_school_user
    Sessions::Users::OTPSchoolUser.new(email: otp_user.email, name: otp_user.name, school_urn: otp_user.urn)
  end

  def otp_user
    @otp_user ||= @otp_form.user
  end
end
