module API
  module OAuth
    class AuthorizationTokenController < ActionController::API
      include API::ClientAuthenticable

      def create
        service = API::OAuth::AuthorizationToken.new(client: current_client, **handshake_params)

        if service.valid?
          token, token_expires_at = service.create
          render json: token_response(token, token_expires_at).to_json, status: :created
        else
          render json: error_message(service).to_json, status: :bad_request
        end
      end

    private

      def handshake_params
        params.permit(:grant_type, :code, :code_verifier, :redirect_uri)
      end

      def token_response(token, token_expires_at)
        {
          access_token: token,
          expires_in: (token_expires_at - Time.zone.now).round,
          token_type: "Bearer"
        }
      end

      def error_message(service)
        {
          error: service.errors.first.message
        }
      end
    end
  end
end
