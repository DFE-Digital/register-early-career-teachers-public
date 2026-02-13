RSpec.describe Schools::ECTInductionDetailsComponent, type: :component do
  let(:appropriate_body_period) { FactoryBot.create(:appropriate_body_period, name: "Alpha Teaching School Hub") }
  let(:teacher) { FactoryBot.create(:teacher, trn: "9876543", trs_first_name: "John", trs_last_name: "Doe") }
  let(:ect) do
    FactoryBot.create(:ect_at_school_period,
                      teacher:,
                      school_reported_appropriate_body: appropriate_body_period,
                      started_on: Date.new(2023, 9, 1))
  end

  before do
    render_inline(described_class.new(ect))
  end

  it "renders the section heading" do
    expect(page).to have_selector("h2.govuk-heading-m", text: "Induction details")
  end

  it "renders the appropriate body row" do
    expect(page).to have_selector(".govuk-summary-list__key", text: "Appropriate body")
    expect(page).to have_selector(".govuk-summary-list__value", text: "Alpha Teaching School Hub")
  end

  context "when induction start date is available" do
    let!(:induction_period) do
      FactoryBot.create(:induction_period, :ongoing, teacher:, appropriate_body_period:, started_on: Date.new(2023, 9, 1))
    end

    before do
      teacher.reload # Reload to pick up the new induction period
      render_inline(described_class.new(ect))
    end

    it "renders the induction start date with appropriate text" do
      expect(page).to have_selector(".govuk-summary-list__key", text: "Induction start date")
      expect(page).to have_selector(".govuk-summary-list__value", text: "1 September 2023")
      expect(page).to have_text("This has been reported by an appropriate body")
    end
  end

  context "when induction start date is not available" do
    it "renders the appropriate message" do
      expect(page).to have_selector(".govuk-summary-list__key", text: "Induction start date")
      expect(page).to have_selector(".govuk-summary-list__value", text: "Yet to be reported by the appropriate body")
    end
  end
end
