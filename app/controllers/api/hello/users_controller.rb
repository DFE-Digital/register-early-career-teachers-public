module API
  module Hello
    class UsersController < ActionController::API
      include API::OAuth::TokenAuthenticable

      def show
        render json: API::Hello::UserSerializer.render(current_authorization)
      end
    end
  end
end
