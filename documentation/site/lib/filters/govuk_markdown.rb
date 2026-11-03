require "govuk_markdown"

Nanoc::Filter.define(:govuk_markdown) do |content, _params|
  govuk_markdown_options = { headings_start_with: "l" }
  redcarpet_options = { fenced_code_blocks: true }

  GovukMarkdown.render(content, govuk_markdown_options, redcarpet_options)
end
