module API
  class GuidanceController < ApplicationController
    skip_before_action :authenticate

    layout 'api_guidance'

    def show
      @latest_release_note = release_notes.first
    end

    def release_notes
      @release_notes = YAML.load_file(
        Rails.root.join('app/views/api/guidance/release_notes.yml'),
        permitted_classes: [Date]
      ).map.with_index { |note, i| API::ReleaseNote.new(**note.symbolize_keys, latest: i.zero?) }
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
