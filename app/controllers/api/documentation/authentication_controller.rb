module API
  module Documentation
    class AuthenticationController < ApplicationController
      layout "api/documentation/api_authentication"

      def show
      end

      def page
        template = "api/documentation/authentication/pages/#{params[:page].underscore}"

        if template_exists?(template)
          render template, layout: "api/documentation/api_authentication"
        else
          render "errors/not_found", status: :not_found
        end
      end
    end
  end
end
