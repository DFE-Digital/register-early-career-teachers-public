RSpec.describe Admin::DataFixes::ParsedCSVComponent, type: :component do
  subject(:component) { described_class.new(parsed_rows) }

  before { render_inline(component) }

  context "when there are no parsed rows" do
    let(:parsed_rows) { nil }

    it "renders nothing" do
      expect(rendered_content).to be_empty
    end
  end

  context "when parsed rows is empty" do
    let(:parsed_rows) { [] }

    it "renders nothing" do
      expect(rendered_content).to be_empty
    end
  end

  context "when there are parsed rows" do
    let(:parsed_rows) do
      [
        { "name" => "John", "age" => "31" },
        { "name" => "Jane", "age" => "30" },
        { "name" => "Mike", "age" => "45" }
      ]
    end

    it "renders a table with the parsed rows" do
      expect(page).to have_table(
        "Parsed rows",
        with_rows: [
          { "name" => "John", "age" => "31" },
          { "name" => "Jane", "age" => "30" },
          { "name" => "Mike", "age" => "45" },
        ]
      )
      table = page.find("table", text: "Parsed rows")
      expect(table).to have_css("tbody tr", count: 3)
    end
  end

  context "when some rows have `nil` values" do
    let(:parsed_rows) do
      [
        { "name" => "John", "age" => "31" },
        { "name" => nil, "age" => "30" },
      ]
    end

    it "renders a table with the parsed rows" do
      expect(page).to have_table(
        "Parsed rows",
        with_rows: [
          { "name" => "John", "age" => "31" },
          { "name" => "", "age" => "30" },
        ]
      )
      table = page.find("table", text: "Parsed rows")
      expect(table).to have_css("tbody tr", count: 2)
    end
  end
end
