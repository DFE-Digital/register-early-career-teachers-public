module HaveSummaryListRow
  class Matcher
    def initialize(key, value: "", visible: :visible)
      @key = key
      @value = value
      @visible = visible
    end

    def matches?(page)
      @page = page
      @rows = @page.find_all("dl.govuk-summary-list dt.govuk-summary-list__key", visible: @visible)
      @matching_row = @rows.find { |it| it.text == @key }

      if @value.blank?
        @matching_row && @matching_row.text == @key
      else
        @sibling = @matching_row&.sibling("dd.govuk-summary-list__value", visible: @visible)
        @sibling && @sibling.text == @value
      end
    end

    def failure_message
      [generic_failure_message, matching_row_failure_message, sibling_failure_message]
        .compact
        .join("\n\n")
    end

    def description
      d = "have summary list row with key \"#{@key}\""
      d += " and value \"#{@value}\"" if @value.present?
      d
    end

  private

    def generic_failure_message
      <<~TXT.squish
        Expected page to have summary list pair with key: "#{@key}" and value:
        "#{@value}", but it did not.
      TXT
    end

    def matching_row_failure_message
      if @rows.present? && @matching_row.blank?
        <<~TXT.squish
          Found #{@rows.size} #{'summary list row'.pluralize(@rows.size)} with
          keys: #{@rows.map { %("#{it.text}") }.join(', ')}.
        TXT
      end
    end

    def sibling_failure_message
      if @matching_row.present?
        %(Found matching summary list row, but its value is "#{@sibling.text}".)
      end
    end
  end

  def have_summary_list_row(key, value: "", visible: :visible) = Matcher.new(key, value:, visible:)
end
