module API
  module Hello
    class DocumentationsController < ApplicationController
      layout "api/documentation/swagger"

      def show
      end
    end
  end
end
