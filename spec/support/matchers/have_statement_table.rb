module HaveStatementTable
  class Matcher
    def initialize(caption:, headings:, rows:, total: nil)
      @caption = caption
      @headings = headings
      @rows = rows
      @total = total
    end

    def matches?(page)
      @page = page
      # Assert table exists with the expected caption
      return false unless page.has_css?("table caption", text: @caption)

      table = page.find("table", text: @caption)
      # Assert table has the expected headings
      return false unless @headings.each_with_index.all? do |heading, index|
        table.has_css?(th_selector(index: index + 1), text: heading)
      end

      # Assert table has the expected number of rows
      return false unless table.has_css?("tbody tr", count: @rows.count)

      # Assert table has the expected cells
      return false unless @rows.each_with_index.all? do |row, index|
        row.each_with_index.all? do |cell, cell_index|
          table.has_css?(td_selector(row: index + 1, cell: cell_index + 1), text: cell)
        end
      end

      # Assert the expected total is displayed as a heading
      if @total
        panel = table.ancestor(".finance-panel")
        total = panel.find(".govuk-heading-s", text: "Total")

        return false unless total.sibling(".govuk-heading-s").has_text?(@total)
      end

      true
    end

    def failure_message
      <<~TXT
        Expected "#{@caption}" table with rows: #{@rows} and total: #{@total}, but
        it could not be found: #{@page.native.inner_html}
      TXT
    end

    def description
      "have statement table with caption \"#{@caption}\", headings \"#{@headings.join(', ')}\", rows \"#{@rows.join(', ')}\", and total \"#{@total}\""
    end

  private

    def td_selector(row:, cell:) = "tbody tr:nth-child(#{row}) td:nth-child(#{cell})"
    def th_selector(index:) = "thead tr th:nth-child(#{index})"
  end

  def have_statement_table(...) = Matcher.new(...)
end
