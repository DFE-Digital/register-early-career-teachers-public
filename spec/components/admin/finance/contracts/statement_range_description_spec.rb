RSpec.describe Admin::Finance::Contracts::StatementRangeDescription, type: :component do
  subject(:component) { described_class.new(first_statement:, last_statement:) }

  context "with no statements" do
    let(:first_statement) { nil }
    let(:last_statement) { nil }

    it "renders 'No statements'" do
      render_inline(component)
      expect(rendered_content).to eq("No statements")
    end
  end

  context "with a single statement" do
    let(:first_statement) { FactoryBot.create(:statement, month: 1, year: 2025) }
    let(:last_statement) { first_statement }

    it "renders the single period" do
      render_inline(component)
      expect(rendered_content).to eq("January 2025")
    end
  end

  context "with multiple statements spanning different periods" do
    let(:first_statement) { FactoryBot.create(:statement, month: 1, year: 2025) }
    let(:last_statement) { FactoryBot.create(:statement, month: 5, year: 2026) }

    it "renders the span from earliest to latest" do
      render_inline(component)
      expect(rendered_content).to eq("January 2025 - May 2026")
    end
  end
end
