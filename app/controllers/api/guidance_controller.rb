module API
  class GuidanceController < ApplicationController
    skip_before_action :authenticate

    layout 'api_guidance'

    def show
    end
  end
end
