module API
  module Hello
    class UsersController < ActionController::API
      include API::OAuth::TokenAuthenticable

      def show
        render json: { name: current_authorization.user_name }
      end
    end
  end
end
