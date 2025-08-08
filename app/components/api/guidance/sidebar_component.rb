module API
  module Guidance
    class SidebarComponent < ViewComponent::Base
      GUIDANCE_PAGES = [
        { title: "API IDs explained", path: "guidance-for-lead-providers/api-ids-explained" },
        { title: "API data states", path: "guidance-for-lead-providers/api-data-states" },
        { title: "Syncing data best practice", path: "guidance-for-lead-providers/data-syncing" },
      ].freeze

      attr_reader :current_path, :page

      def initialize(current_path:, page:)
        @current_path = current_path
        @page = page
      end

      def render?
        page.to_s.starts_with?("guidance-for-lead-providers")
      end

      def structure
        GUIDANCE_PAGES.map do |p|
          path = api_guidance_page_path(p[:path])
          Struct.new(:name, :href, :prefix, :nodes).new(p[:title], path, path, [])
        end
      end
    end
  end
end
