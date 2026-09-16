module API
  module OAuth
    class RevocationsController < ActionController::API
      include API::OAuth::ClientAuthenticable

      before_action :set_authorization

      def create
        API::OAuth::Authorizations::RevocationRequest.new(authorization: @authorization).revoke!

        render status: :ok
      end

    private

      def set_authorization
        @authorization = current_client.authorization_for_token(token: params.permit(:token)[:token])
      end
    end
  end
end
