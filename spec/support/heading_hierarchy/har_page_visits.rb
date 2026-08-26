require "json"
require "tempfile"

module HeadingHierarchy
  PageVisit = Struct.new(:url, :content, keyword_init: true)

  class HARPageVisitReader
    def initialize(path)
      @path = path
    end

    def page_visits
      har_entries.filter_map { |entry| page_visit(entry) }
    end

  private

    def har_entries
      JSON.parse(File.read(@path)).dig("log", "entries") || []
    end

    def page_visit(entry)
      return unless entry["_resourceType"] == "document"

      response = entry.fetch("response")
      return if response.fetch("redirectURL").present?

      response_content = response.fetch("content")
      return unless response_content.fetch("mimeType", "").start_with?("text/html")

      url = entry.dig("request", "url")
      content = response_content["text"]
      return unless content

      PageVisit.new(url:, content:)
    end
  end

  class HARPageVisitRecorder
    def initialize(page, base_url:)
      @page = page
      @base_url = base_url
      @har_file = Tempfile.new(["heading-hierarchy", ".har"])
      @har_file.close
    end

    def start
      @page.context.tracing.start_har(
        @har_file.path,
        content: "embed",
        mode: "minimal",
        urlFilter: %r{^#{Regexp.escape(@base_url)}/(?!assets/)}
      )
    rescue StandardError
      @har_file.unlink
      raise
    end

    def stop
      @page.context.tracing.stop_har
      HARPageVisitReader.new(@har_file.path).page_visits
    ensure
      @har_file.unlink
    end
  end
end
