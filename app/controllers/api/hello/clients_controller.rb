module API
  module Hello
    class ClientsController < ActionController::API
      include API::OAuth::ClientAuthenticable

      def show
        render json: API::Hello::ClientSerializer.render(current_client)
      end
    end
  end
end
