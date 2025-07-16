module API
  class ReleaseNote
    attr_accessor :title, :date, :body, :tags

    def initialize(title:, date:, body:, tags:)
      @title = title
      @date = date.to_formatted_s(:govuk)
      @body = render(body)
      @tags = render_tags(tags)
    end

  private

    def render(markdown)
      GovukMarkdown.render(markdown.to_str, { strip_front_matter: false, headings_start_with: 'l' })
    end

    def render_tags(tags)
      API::TagsRenderer.render(tags)
    end
  end
end
