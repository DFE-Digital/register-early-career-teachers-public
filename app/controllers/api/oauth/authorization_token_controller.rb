module API
  module OAuth
    class AuthorizationTokenController < ActionController::API
      include API::OAuth::ClientAuthenticable

      def create
        service = API::OAuth::AuthorizationToken.new(client: current_client, **authorization_token_params)

        if service.valid? && (authorization = service.create) # rubocop:disable Rails/SaveBang
          render json: token_payload_for(authorization).to_json, status: :created
        else
          render json: error_message(service).to_json, status: :bad_request
        end
      end

    private

      def authorization_token_params
        params.permit(:grant_type, :code, :code_verifier, :redirect_uri)
      end

      def token_payload_for(authorization)
        {
          access_token: authorization.token,
          expires_in: authorization.seconds_to_token_expiry,
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
