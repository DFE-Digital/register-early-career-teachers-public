module API
  module Guidance
    class SidebarComponent < ApplicationComponent
      GUIDANCE_PREFIX = "guidance-for-lead-providers"
      GUIDANCE_PAGES = [
        { title: "API IDs explained", path: "api-ids-explained" },
        { title: "API data states", path: "api-data-states" },
        { title: "Create, view and update partnerships", path: "create-view-and-update-partnerships" },
        { title: "Keeping data in sync", path: "keeping-data-in-sync" },
        { title: "How to test the API effectively", path: "how-to-test-the-api-effectively" },
        { title: "How we assign participant schedules", path: "how-we-assign-participant-schedules" },
      ].freeze

      attr_reader :current_path, :page

      def initialize(current_path:, page:)
        @current_path = current_path
        @page = page
      end

      def render?
        page.to_s.starts_with?(GUIDANCE_PREFIX)
      end

      def structure
        node = Struct.new(:name, :href, :prefix, :nodes)

        GUIDANCE_PAGES.map do |p|
          path = api_guidance_page_path("#{GUIDANCE_PREFIX}/#{p[:path]}")
          node.new(p[:title], path, path, [])
        end
      end
    end
  end
end
