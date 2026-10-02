module API
  module Documentation
    class AuthenticationController < ApplicationController
      layout "api/documentation/api_authentication"

      before_action :set_api_base_url

      def show
      end

      def page
        template = "api/documentation/authentication/pages/#{params[:page].underscore}"

        if template_exists?(template)
          render template
        else
          render "errors/not_found", status: :not_found
        end
      end

    private

      def set_api_base_url
        @api_base_url = Rails.application.config.service_url || request.base_url
      end
    end
  end
end
