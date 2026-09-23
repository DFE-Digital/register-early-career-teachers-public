module API
  module Hello
    class WorldsController < ActionController::API
      def show
        render json: { message: "Hello World" }
      end
    end
  end
end
