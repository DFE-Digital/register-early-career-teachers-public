module API
  module OAuth
    class RevokeAuthorizationController < ActionController::API
      include API::OAuth::ClientAuthenticable

      def revoke
        API::OAuth::Authorizations::Revoke.new(client: current_client, token:).revoke!

        render status: :ok
      end

    private

      def token
        params.permit(:token)[:token]
      end
    end
  end
end
