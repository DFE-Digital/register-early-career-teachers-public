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
      expect(page).to have_css("table caption", text: "Parsed rows")
      table = page.find("table", text: "Parsed rows")
      expect(table).to have_css("thead tr th:nth-child(1)", text: "name")
      expect(table).to have_css("thead tr th:nth-child(2)", text: "age")
      expect(table).to have_css("tbody tr", count: 3)
      expect(table).to have_css("tbody tr:nth-child(1) td:nth-child(1)", text: "John")
      expect(table).to have_css("tbody tr:nth-child(1) td:nth-child(2)", text: "31")
      expect(table).to have_css("tbody tr:nth-child(2) td:nth-child(1)", text: "Jane")
      expect(table).to have_css("tbody tr:nth-child(2) td:nth-child(2)", text: "30")
      expect(table).to have_css("tbody tr:nth-child(3) td:nth-child(1)", text: "Mike")
      expect(table).to have_css("tbody tr:nth-child(3) td:nth-child(2)", text: "45")
    end
  end
end
