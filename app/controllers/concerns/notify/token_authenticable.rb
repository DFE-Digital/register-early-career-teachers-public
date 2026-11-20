module Notify::TokenAuthenticable
  extend ActiveSupport::Concern
  include ActionController::HttpAuthentication::Token::ControllerMethods

  included do
    before_action :authenticate
  end

private

  def authenticate
    authenticate_request || head(:unauthorized)
  end

  def authenticate_request
    authenticate_with_http_token { valid_token?(it) }
  end

  def valid_token?(token)
    return false unless expected_token

    ActiveSupport::SecurityUtils.secure_compare(token, expected_token)
  end

  def expected_token
    Rails.application.config.notify_delivery_receipts_bearer_token
  end
end
