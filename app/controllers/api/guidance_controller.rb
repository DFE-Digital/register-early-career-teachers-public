module API
  class GuidanceController < ApplicationController
    skip_before_action :authenticate

    layout 'api_guidance', only: 'show'

    def show
    end

    def page
      path = params[:page]

      render template: 'api/guidance/' + path
    end
  end
end
