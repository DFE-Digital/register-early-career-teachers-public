module API
  module OAuth
    class RevokeAuthorizationController < ActionController::API
      include API::OAuth::ClientAuthenticable

      def revoke
        API::OAuth::Authorizations::Revoke.new(authorization:).revoke!

        render status: :ok
      end

    private

      def authorization
        current_client.authorization_for_token(token:)
      end

      def token
        params.permit(:token)[:token]
      end
    end
  end
end
