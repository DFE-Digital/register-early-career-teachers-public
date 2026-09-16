module API
  module OAuth
    class AccessTokensController < ActionController::API
      include API::OAuth::ClientAuthenticable

      def create
        authorization = current_client.authorization_for(code: params[:code])
        access_token_request = AccessTokenRequest.new(authorization:, **access_token_params)

        if access_token_request.valid?
          access_token_request.exchange_code_for_token!

          render json: access_token_request.access_token, status: :created
        else
          render json: access_token_request.error_message, status: :bad_request
        end
      end

    private

      def access_token_params
        params.permit(:grant_type, :code_verifier, :redirect_uri)
      end
    end
  end
end
