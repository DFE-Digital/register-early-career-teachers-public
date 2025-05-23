module API
  class ReleaseNote
    attr_accessor :title, :date, :body

    def initialize(title:, date:, body:)
      @title = title
      @date = date.to_formatted_s(:govuk)
      @body = render(body)
    end

  private

    def render(markdown)
      GovukMarkdown.render(markdown.to_str, { strip_front_matter: false, headings_start_with: 'l' })
    end
  end
end
