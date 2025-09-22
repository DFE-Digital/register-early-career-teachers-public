class PagesController < ApplicationController
  def home
    redirect_to(post_login_redirect_path) and return if authenticated?

    redirect_to(ab_landing_path) unless Rails.application.config.enable_schools_interface
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
