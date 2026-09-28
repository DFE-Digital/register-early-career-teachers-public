module API
  module Documentation
    class AuthorizationController < ApplicationController
      # layout "api_documentation"

      def show
        render layout: "api_documentation"
        # render "api/documentation/authorization/show", layout: "api/documentation/training/api_guidance"
      end
    end
  end
end
