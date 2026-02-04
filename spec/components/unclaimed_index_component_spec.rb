RSpec.describe UnclaimedIndexComponent, type: :component do
  let(:appropriate_body_period) { FactoryBot.create(:appropriate_body_period) }
  let(:component) { described_class.new(appropriate_body_period:) }

  before do
    render_inline(component)
  end

  it "displays the intro text" do
    expect(page).to have_css(".govuk-body", text: "This is live data that is updated when")
  end

  it "renders the detailed review section" do
    expect(page).to have_css("h2", text: "Check records and claim an ECT")
  end

  describe "#period" do
    context "when the current month is after May" do
      it "returns the current year and next year" do
        travel_to(Date.new(2024, 6, 1)) do
          expect(component.period).to eq("2024/2025")
        end
      end
    end

    context "when the current month is May or earlier" do
      it "returns the previous year and current year" do
        travel_to(Date.new(2024, 5, 1)) do
          expect(component.period).to eq("2023/2024")
        end
      end
    end
  end
end
