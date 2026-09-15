module API
  module OAuth
    class AccessTokensController < ActionController::API
      include API::OAuth::ClientAuthenticable

      def create
        access_token_request = AccessTokenRequest.new(client: current_client, **access_token_params)

        if access_token_request.valid?
          authorization = Authorizations::ExchangeCodeForToken.new(access_token_request:).call

          render json: token_payload_for(authorization).to_json, status: :created
        else
          render json: error_message(access_token_request).to_json, status: :bad_request
        end
      end

    private

      def access_token_params
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
