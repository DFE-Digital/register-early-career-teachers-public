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
        "swagger-api-documentation" => "swagger_api_documentation",
        "guidance-for-lead-providers" => "guidance_for_lead_providers",
        "sandbox" => "sandbox",
        "guidance-for-lead-providers/api-data-states" => "guidance_for_lead_providers/api_data_states",
        "guidance-for-lead-providers/data-syncing" => "guidance_for_lead_providers/data_syncing",
        "guidance-for-lead-providers/ids-explained" => "guidance_for_lead_providers/ids_explained",
      }.fetch(path)

      render "api/guidance/" + template
    end
  end
end
