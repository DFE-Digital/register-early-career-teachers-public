module API
  module OAuth
    class AuthorizationTokenController < ActionController::API
      include API::ClientAuthenticable

      def create
        service = API::OAuth::AuthorizationToken.new(client: current_client, **authorization_token_params)

        if service.valid?
          token, token_expires_at = service.create
          render json: serializer.render({ access_token: token, token_expires_at:, }), status: :created
        else
          render json: error_message(service).to_json, status: :bad_request
        end
      end

    private

      def authorization_token_params
        params.permit(:grant_type, :code, :code_verifier, :redirect_uri)
      end

      def error_message(service)
        {
          error: service.errors.first.message
        }
      end

      def serializer
        API::OAuth::AuthorizationTokenSerializer
      end
    end
  end
end
