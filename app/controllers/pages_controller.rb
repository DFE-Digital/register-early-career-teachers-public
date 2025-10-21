class PagesController < ApplicationController
  def home
    redirect_to(post_login_redirect_path) and return if authenticated?

    redirect_to(ab_landing_path) unless Rails.application.config.enable_schools_interface
  end

  # Unrecognised DfE Sign In user (org/role)
  def access_denied
    if (@organisation_name = session.delete(:invalid_user_organisation_name)).nil?
      redirect_to root_path
    end
    @dfe_user_account = Rails.application.config.dfe_sign_in_user_account
  end

  def support
  end

  def cookies
  end

  def accessibility
  end

  def privacy
  end

  def school_requirements
  end
end
