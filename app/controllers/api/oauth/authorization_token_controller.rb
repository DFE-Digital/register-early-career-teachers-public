module API
  module OAuth
    class AuthorizationTokenController < ActionController::API
      include API::OAuth::ClientAuthenticable

      def create
        authorization_token_request = AuthorizationTokenRequest.new(client: current_client, **authorization_token_params)

        if authorization_token_request.valid?
          authorization = Authorizations::ExchangeCodeForToken.new(authorization_token_request:).call

          render json: token_payload_for(authorization).to_json, status: :created
        else
          render json: error_message(authorization_token_request).to_json, status: :bad_request
        end
      end

    private

      def authorization_token_params
        params.permit(:grant_type, :code, :code_verifier, :redirect_uri)
      end

      def token_payload_for(authorization)
        {
          access_token: authorization.token,
          expires_in: authorization.seconds_to_token_expiration,
          token_type: "Bearer",
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
