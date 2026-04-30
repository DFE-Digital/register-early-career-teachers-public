class ApplicationController < ActionController::Base
  include Authentication
  include DfE::Analytics::Requests
  include TimeTravellable

  before_action :set_sentry_user

  include Pagy::Backend

  # Used by Blazer
  # @see config/blazer.yml
  # @return [User, nil]
  delegate :user, to: :current_user, allow_nil: true

  # FIXME: path helpers bork for /admin/foo/bar
  # Used by Blazer to restrict access
  # @see config/blazer.yml
  # @return [String, nil]
  def require_admin
    redirect_to("/sign-in") unless current_user&.dfe_user?
  end

  def set_sentry_user
    Sentry.set_user(email: current_user&.email)
  end

private

  def append_info_to_payload(payload)
    super
    payload[:current_user_class] = current_user&.class&.name
    payload[:current_user_id] = current_user.try(:id)
  end
end
