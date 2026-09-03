module API
  module ClientAuthenticable
    extend ActiveSupport::Concern
    include ActionController::HttpAuthentication::Basic::ControllerMethods

    included do
      before_action :authenticate
    end

  private

    def authenticate
      authenticate_request || render_unauthorized
    end

    def authenticate_request
      authenticate_with_http_basic do |client_id, secret|
        @authenticated_client = authenticate_client(client_id:, secret:)
      end
    end

    def authenticate_client(client_id:, secret:)
      client = API::OAuth::Client.find_by(client_id:)
      return if client.blank? || client.client_secret_digest != Digest::SHA256.hexdigest(secret)
      client
    end

    def render_unauthorized
      render json: { error: "invalid_client" }.to_json, status: :unauthorized
    end

    def current_client
      @current_client ||= @authenticated_client
    end
  end
end
