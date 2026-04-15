module SignInHelper
  def school_sign_in_cta(text)
    return govuk_button_to(text, "/auth/dfe_sign_in") if direct_school_dfe_sign_in?

    govuk_button_link_to(text, sign_in_path)
  end

  def direct_dfe_sign_in_available?
    Rails.application.config.dfe_sign_in_enabled &&
      !Rails.application.config.enable_personas
  end

private

  def direct_school_dfe_sign_in?
    Rails.application.config.enable_direct_school_dfe_sign_in &&
      direct_dfe_sign_in_available?
  end
end
