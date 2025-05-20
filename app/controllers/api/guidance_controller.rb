module API
  class GuidanceController < ApplicationController
    skip_before_action :authenticate

    layout 'api_guidance', only: 'show'

    def show
    end

    def release_notes
      @release_notes = YAML.load_file(
        Rails.root.join('app/views/api/guidance/release_notes.yml'),
        permitted_classes: [Date]
      ).map { |note| API::ReleaseNote.new(**note.symbolize_keys) }
    end

    def page
      path = params[:page]

      template = {
        "page-1" => "page_1",
        "page-2" => "page_2",
        "page-3" => "page_3",
      }.fetch(path)

      render "api/guidance/" + template
    end
  end
end
