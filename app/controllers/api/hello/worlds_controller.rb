module API
  module Hello
    class WorldsController < ActionController::API
      def show
        render json: API::Hello::WorldSerializer.render({ message: "Hello World" })
      end
    end
  end
end
