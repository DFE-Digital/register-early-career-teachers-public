module API
  class GuidanceController < ApplicationController
    skip_before_action :authenticate

    layout 'api_guidance'

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
        "how-to-use-api" => "how_to_use_api",
        "technical-documentation" => "technical_documentation",
        "early-career-training-programme-guidance" => "ect_programme_guidance",
        "sandbox" => "sandbox",
      }.fetch(path)

      render "api/guidance/" + template
    end
  end
end
