class PagesController < ApplicationController
  after_action :allow_search_engine_indexing, only: :home

  def home
    redirect_to(post_login_redirect_path) and return if authenticated?
  end

  # Unrecognised DfE Sign In user (org/role)
  def access_denied
    @dfe_sign_in_organisation_details = organisation_details_from_session
    @dfe_sign_in_request_organisation_url =
      Rails.application.config.dfe_sign_in_request_organisation_url
    @dfe_sign_in_my_services_url =
      Rails.application.config.dfe_sign_in_my_services_url
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

private

  def organisation_details_from_session
    Sessions::DfESignIn::OrganisationDetails.new(
      session[:invalid_organisation_details]
    )
  end
end
