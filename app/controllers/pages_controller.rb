class PagesController < ApplicationController
  after_action :allow_search_engine_indexing, only: :home

  DFE_SIGN_IN_REQUEST_ORGANISATION_URL =
    "https://services.signin.education.gov.uk/request-organisation/search"

  DFE_SIGN_IN_MY_SERVICES_URL =
    "https://services.signin.education.gov.uk/my-services"

  def home
    redirect_to(post_login_redirect_path) and return if authenticated?
  end

  # Unrecognised DfE Sign In user (org/role)
  def access_denied
    @organisation_name = session[:invalid_user_organisation_name]
    @dfe_sign_in_request_organisation_url = DFE_SIGN_IN_REQUEST_ORGANISATION_URL
    @dfe_sign_in_my_services_url = DFE_SIGN_IN_MY_SERVICES_URL
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
