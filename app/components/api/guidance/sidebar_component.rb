module API
  module Guidance
    class SidebarComponent < ViewComponent::Base
      GUIDANCE_PREFIX = "guidance-for-lead-providers".freeze
      GUIDANCE_PAGES = [
        { title: "API IDs explained", path: "api-ids-explained" },
        { title: "API data states", path: "api-data-states" },
        { title: "Syncing data best practice", path: "data-syncing" },
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
