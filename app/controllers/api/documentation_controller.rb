# require "api/version"

module API
  class DocumentationController < ApplicationController
    skip_before_action :authenticate

    layout "api_docs"

    def index
      @version = params[:version]

      raise ActionController::RoutingError, "Not found" unless API::Version.exists?(@version)
    end
  end
end
