module API
  module Hello
    class DocumentationsController < ApplicationController
      layout "api_docs"

      def show
        @version = "hello"
      end
    end
  end
end
