module API
  module Docs
    module LeadProvider
      class ReleaseNotesController < ApplicationController
        include ReleaseNotes

        layout "api/docs/lead_provider/api_guidance"

        def index
        end

        def show
          @release_note = release_notes.find { |note| note.slug == params[:slug] }

          unless @release_note
            render "errors/not_found", status: :not_found
          end
        end
      end
    end
  end
end
