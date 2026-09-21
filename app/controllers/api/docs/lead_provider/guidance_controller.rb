module API
  module Docs
    module LeadProvider
      class GuidanceController < ApplicationController
        include ReleaseNotes

        layout "api/docs/lead_provider/api_home"

        after_action :allow_search_engine_indexing, only: :show

        def show
          @latest_release_note = release_notes.first
        end

        def page
          template = "api/docs/lead_provider/guidance/#{params[:page].underscore}"

          if template_exists?(template)
            render template, layout: "api/docs/lead_provider/api_guidance"
          else
            render "errors/not_found", status: :not_found
          end
        end
      end
    end
  end
end
