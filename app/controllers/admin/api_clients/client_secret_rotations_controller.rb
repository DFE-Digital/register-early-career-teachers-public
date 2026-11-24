module Admin
  module APIClients
    class ClientSecretRotationsController < AdminController
      layout "full"

      before_action :set_client

      def new
      end

      def create
        API::OAuth::Clients.new(author: current_user).rotate_secret!(client: @client)
        no_store
      end

    private

      def authorised? = super && current_user.product_team?

      def set_client
        @client = API::OAuth::Client.find(params.expect(:api_client_id))
      end
    end
  end
end
