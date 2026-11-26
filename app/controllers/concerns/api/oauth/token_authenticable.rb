module API::OAuth::TokenAuthenticable
  extend ActiveSupport::Concern
  include ActionController::HttpAuthentication::Token::ControllerMethods

  included do
    class_attribute :accept_legacy_lead_provider_api_tokens, default: false

    before_action :authenticate
    attr_reader :current_authorization, :current_legacy_lead_provider_api_token

    delegate :appropriate_body, :client, to: :current_authorization, private: true
    delegate :lead_provider, to: :current_legacy_lead_provider_api_token, private: true
  end

private

  def authenticate
    authenticate_request || render_unauthorized
  end

  def authenticate_request
    authenticate_with_http_token do |token|
      if accept_legacy_lead_provider_api_tokens
        @current_legacy_lead_provider_api_token = API::TokenManager.find_lead_provider_api_token(token:)
      else
        @current_authorization = API::OAuth::Authorization.active.with_token(token).take
      end

      current_authorization || current_legacy_lead_provider_api_token
    end
  end

  def render_unauthorized
    if request.authorization.present?
      headers["WWW-Authenticate"] = %(Bearer error="invalid_token")
      render json: API::OAuth::ErrorSerializer.render({ error: "invalid_token" }), status: :unauthorized
    else
      headers["WWW-Authenticate"] = "Bearer"
      head :unauthorized
    end
  end
end
