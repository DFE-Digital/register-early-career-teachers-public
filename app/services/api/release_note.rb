module API
  class ReleaseNote
    class InvalidNoteError < StandardError; end

    attr_accessor :title, :date, :body, :tags, :slug

    def initialize(title:, date:, body:, tags:)
      @title = title
      @date = date.to_formatted_s(:govuk)
      @body = render(body)
      @tags = tags
      @slug = [date.iso8601, title].join("-").parameterize
    rescue NoMethodError => _e
      raise InvalidNoteError, "Invalid release note"
    end

  private

    def render(markdown)
      raise InvalidNoteError, "Invalid release note" if markdown.blank?

      GovukMarkdown.render(markdown.to_str, { strip_front_matter: false, headings_start_with: "l" })
    end
  end
end
