module API
  class ReleaseNotesController < ApplicationController
    include ReleaseNotes

    skip_before_action :authenticate

    layout 'api_guidance'

    def index
    end

    def show
      @release_note = release_notes.find { |note| note.slug == params[:slug] }

      unless @release_note
        render 'errors/not_found', status: :not_found
      end
    end
  end
end
