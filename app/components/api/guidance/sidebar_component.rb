module API
  module Guidance
    class SidebarComponent < ApplicationComponent
      GUIDANCE_PREFIX = "guidance-for-lead-providers"
      GUIDANCE_DIR = Rails.root.join("app/views/api/guidance/guidance_for_lead_providers/*.md")
      FRONT_MATTER_REGEX = /^\s*---(?<front_matter>.*?)---\s/m

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

        self.class.guidance_pages.map do |p|
          path = api_guidance_page_path("#{GUIDANCE_PREFIX}/#{p[:path]}")
          node.new(p[:title], path, path, [])
        end
      end

      def self.guidance_pages
        Dir.glob(GUIDANCE_DIR).filter_map { |file|
          frontmatter = extract_frontmatter(file)
          next unless frontmatter

          {
            title: frontmatter["sidebar_title"] || frontmatter["title"],
            path: File.basename(file, ".md").tr("_", "-"),
            sidebar_position: frontmatter["sidebar_position"] || Float::INFINITY
          }
        }.sort_by { |p| p[:sidebar_position] }
      end

      def self.extract_frontmatter(file)
        content = File.read(file)
        match = content.match(FRONT_MATTER_REGEX)
        return unless match

        YAML.safe_load(match[:front_matter])
      end
    end
  end
end
