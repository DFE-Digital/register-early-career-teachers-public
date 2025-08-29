module API
  class ReleaseNote
    attr_accessor :title, :date, :body, :tags, :latest, :slug

    def initialize(title:, date:, body:, tags:, latest: false)
      @title = title
      @date = date.to_formatted_s(:govuk)
      @body = render(body)
      @tags = tags
      @latest = latest
      @slug = [date.iso8601, title].join("-").parameterize
    end

    def latest? = latest

  private

    def render(markdown)
      GovukMarkdown.render(markdown.to_str, { strip_front_matter: false, headings_start_with: 'l' })
    end
  end
end
