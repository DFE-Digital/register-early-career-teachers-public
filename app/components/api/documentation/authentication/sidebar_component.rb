module API
  module Documentation
    module Authentication
      class SidebarComponent < ApplicationComponent
        PAGES_PREFIX = "pages"
        PAGES_DIR = Rails.root.join("app/views/api/documentation/authentication/pages/*.html.erb")
        FRONT_MATTER_REGEX = /^\s*---(?<front_matter>.*?)---\s/m

        attr_reader :current_path, :page

        def initialize(current_path:, page:)
          @current_path = current_path
          @page = page
        end

        def structure
          node = Struct.new(:name, :href, :prefix, :nodes)

          self.class.pages.map do |p|
            path = api_documentation_authentication_page_path(p[:path].to_s)
            node.new(p[:title], path, path, [])
          end
        end

        def self.pages
          Dir.glob(PAGES_DIR).filter_map { |file|
            frontmatter = extract_frontmatter(file)
            next unless frontmatter

            {
              title: frontmatter["sidebar_title"] || frontmatter["title"],
              path: File.basename(file, ".html.erb").tr("_", "-"),
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
end
