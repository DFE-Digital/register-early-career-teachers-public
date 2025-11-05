class ApplicationController < ActionController::Base
  include Authentication
  include DfE::Analytics::Requests

  before_action :set_sentry_user

  include Pagy::Backend

  # Used by Blazer
  # @see config/blazer.yml
  # @return [User, nil]
  delegate :user, to: :current_user, allow_nil: true

  # Used by Blazer to restrict access
  # @see config/blazer.yml
  # @return [String, nil]
  def require_admin
    redirect_to("/sign-in") unless current_user&.dfe_user?
  end

  def set_sentry_user
    Sentry.set_user(email: current_user&.email)
  end
end
