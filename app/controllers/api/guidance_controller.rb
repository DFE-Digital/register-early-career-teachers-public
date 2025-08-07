module API
  class GuidanceController < ApplicationController
    skip_before_action :authenticate
    before_action :set_sidebar, only: [:page]

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

  private

    def guidance_pages
      [
        { title: "API IDs explained", path: "guidance-for-lead-providers/ids-explained" },
        { title: "API data states", path: "guidance-for-lead-providers/api-data-states" },
        { title: "Syncing data best practice", path: "guidance-for-lead-providers/data-syncing" },
      ]
    end

    def set_sidebar
      return unless params[:page].starts_with?("guidance-for-lead-providers")

      @sidebar = guidance_pages.map do |p|
        path = api_guidance_page_path(p[:path])
        Struct.new(:name, :href, :prefix, :nodes).new(p[:title], path, path, [])
      end
    end
  end
end
