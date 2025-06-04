module API
  module TokenAuthenticatable
    extend ActiveSupport::Concern
    include ActionController::HttpAuthentication::Token::ControllerMethods

    included do
      before_action :authenticate
    end

  private

    def authenticate
      authenticate_token || render_unauthorized
    end

    def authenticate_token
      authenticate_with_http_token do |token|
        @current_api_token = TokenManager.find_lead_provider_api_token(token:)
      end
    end

    def render_unauthorized
      render json: { error: "HTTP Token: Access denied" }.to_json, status: :unauthorized
    end

    def current_lead_provider
      @current_lead_provider ||= @current_api_token&.lead_provider
    end
  end
end
