module API
  class GuidanceController < ApplicationController
    include ReleaseNotes

    layout 'api_guidance'

    def show
      @latest_release_note = release_notes.first
    end

    def page
      template = "api/guidance/#{params[:page].underscore}"

      if template_exists?(template)
        render template
      else
        render 'errors/not_found', status: :not_found
      end
    end
  end
end
