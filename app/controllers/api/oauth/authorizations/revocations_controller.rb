module API
  module OAuth
    module Authorizations
      class RevocationsController < ActionController::API
        include API::OAuth::ClientAuthenticable

        before_action :set_authorization

        def create
          API::OAuth::Authorizations::RevocationRequest.new(authorization: @authorization).revoke!

          head :ok
        end

      private

        def set_authorization
          @authorization = current_client.active_authorization_for_token(token: params.require(:token))
        end
      end
    end
  end
end
