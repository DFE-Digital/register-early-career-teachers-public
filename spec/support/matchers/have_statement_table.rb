module HaveStatementTable
  class Matcher
    def initialize(headings:, rows:, caption: nil, total: nil, total_label: "Total", selector: nil)
      @caption = caption
      @headings = headings
      @rows = rows
      @total = total
      @total_label = total_label
      @selector = selector
    end

    def matches?(page)
      @page = page

      # Assert table exists with the expected caption, if present
      return false if @caption && !page.has_css?("table caption", text: @caption)

      # Find the table by caption or selector
      table = find_table(@page)
      return false unless table

      # Assert table has the expected headings
      return false unless @headings.each_with_index.all? do |heading, index|
        table.has_css?(header_selector(index: index + 1), text: heading)
      end

      # Assert table has the expected number of rows
      return false unless table.has_css?("tbody tr", count: @rows.count)

      # Assert table has the expected cells
      return false unless @rows.each_with_index.all? do |row, index|
        row.each_with_index.all? do |cell, cell_index|
          table.has_css?(cell_selector(row: index + 1, cell: cell_index + 1), text: cell)
        end
      end

      # Assert the expected total is displayed as a heading
      if @total
        panel = table.ancestor(".finance-panel")
        total = panel.find(".govuk-heading-s", text: @total_label)

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

    def cell_selector(row:, cell:)
      "tbody tr:nth-child(#{row}) td:nth-child(#{cell}), tbody tr:nth-child(#{row}) th:nth-child(#{cell})"
    end

    def header_selector(index:) = "thead tr th:nth-child(#{index})"

    def find_table(page)
      return page.find("table", text: @caption) if @caption

      page.find(@selector)
    end
  end

  def have_statement_table(...) = Matcher.new(...)
end
