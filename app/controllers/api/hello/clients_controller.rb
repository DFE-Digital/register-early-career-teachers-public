module API
  module Hello
    class ClientsController < ActionController::API
      include API::OAuth::ClientAuthenticable

      def show
        render json: { name: current_client.name }
      end
    end
  end
end
