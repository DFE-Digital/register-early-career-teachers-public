module Admin::DataFixes
  class ParsedCSVComponent < ApplicationComponent
    def initialize(parsed_rows)
      @parsed_rows = parsed_rows
    end

    def render? = @parsed_rows&.any?

    def call
      govuk_table(
        caption: "Parsed rows",
        head: @parsed_rows.first.keys,
        rows: @parsed_rows.collect(&:values)
      )
    end
  end
end
