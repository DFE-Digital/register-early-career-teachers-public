module API
  module OAuth
    class AuthorizationTokenController < ActionController::API
      include API::ClientAuthenticable

      def create
        service = API::OAuth::AuthorizationToken.new(client: current_client, **handshake_params)

        if service.valid?
          authorization = service.create
          render json: authorization
        else
          render json: error_message
        end

      end

    private

      def handshake_params
        params.permit(:grant_type, :code, :code_verifier, :redirect_uri)
      end

      def error_message
        { error: "blah blah" }.to_json
      end
    end
  end
end
