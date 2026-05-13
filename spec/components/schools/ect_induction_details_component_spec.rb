RSpec.describe Schools::ECTInductionDetailsComponent, type: :component do
  let(:appropriate_body_period) { FactoryBot.create(:appropriate_body_period, name: "Alpha Teaching School Hub") }
  let(:teacher) { FactoryBot.create(:teacher, trn: "9876543", trs_first_name: "John", trs_last_name: "Doe") }
  let(:ect) do
    FactoryBot.create(:ect_at_school_period,
                      teacher:,
                      school_reported_appropriate_body: appropriate_body_period,
                      started_on: Date.new(2023, 9, 1))
  end

  let(:latest_induction_period) { nil }
  let(:past_induction_period) { nil }

  before do
    past_induction_period
    latest_induction_period
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

  context "when the ECT has no induction periods" do
    context "when the appropriate body has not been reported" do
      let(:ect) do
        FactoryBot.create(:ect_at_school_period,
                          teacher:,
                          school_reported_appropriate_body: nil,
                          started_on: Date.new(2023, 9, 1))
      end

      it "renders not reported for the appropriate body" do
        expect(page).to have_selector(".govuk-summary-list__key", text: "Appropriate body")
        expect(page).to have_selector(".govuk-summary-list__value", text: "Not reported")
      end

      it "renders the induction start date fallback" do
        expect(page).to have_selector(".govuk-summary-list__key", text: "Induction start date")
        expect(page).to have_selector(".govuk-summary-list__value", text: "Yet to be reported by the appropriate body")
      end
    end

    context "when the appropriate body is reported" do
      it "renders the reported appropriate body" do
        expect(page).to have_selector(".govuk-summary-list__key", text: "Appropriate body")
        expect(page).to have_selector(".govuk-summary-list__value", text: "Alpha Teaching School Hub")
        expect(page).not_to have_selector(".govuk-summary-list__value", text: "Not reported")
      end
    end
  end

  context "when the ECT has one induction period" do
    let(:latest_appropriate_body_period) { FactoryBot.create(:appropriate_body_period, name: "Current AB") }
    let!(:latest_induction_period) do
      FactoryBot.create(:induction_period, :ongoing, teacher:, appropriate_body_period: latest_appropriate_body_period, started_on: Date.new(2023, 9, 1))
    end

    it "renders the appropriate body from the induction period" do
      expect(page).to have_selector(".govuk-summary-list__key", text: "Appropriate body")
      expect(page).to have_selector(".govuk-summary-list__value", text: "Current AB")
      expect(page).not_to have_selector(".govuk-summary-list__value", text: "Alpha Teaching School Hub")
      expect(page).not_to have_selector(".govuk-summary-list__value", text: "Not reported")
    end

    it "renders the induction start date from the induction period, with a hint" do
      expect(page).to have_selector(".govuk-summary-list__key", text: "Induction start date")
      expect(page).to have_selector(".govuk-summary-list__value", text: "1 September 2023This has been reported by an appropriate body")
      expect(page).not_to have_selector(".govuk-summary-list__value", text: "Yet to be reported by the appropriate body")
    end
  end

  context "when the ECT has multiple induction periods" do
    let(:past_appropriate_body_period) { FactoryBot.create(:appropriate_body_period, name: "Past AB") }
    let!(:past_induction_period) do
      FactoryBot.create(:induction_period, teacher:, appropriate_body_period: past_appropriate_body_period, started_on: Date.new(2023, 9, 1), finished_on: Date.new(2024, 7, 1))
    end
    let(:latest_appropriate_body_period) { FactoryBot.create(:appropriate_body_period, name: "Current AB") }
    let!(:latest_induction_period) do
      FactoryBot.create(:induction_period, :ongoing, teacher:, appropriate_body_period: latest_appropriate_body_period, started_on: Date.new(2024, 9, 1))
    end

    it "renders the appropriate body from the latest induction period" do
      expect(page).to have_selector(".govuk-summary-list__key", text: "Appropriate body")
      expect(page).to have_selector(".govuk-summary-list__value", text: "Current AB")
      expect(page).not_to have_selector(".govuk-summary-list__value", text: "Past AB")
      expect(page).not_to have_selector(".govuk-summary-list__value", text: "Alpha Teaching School Hub")
      expect(page).not_to have_selector(".govuk-summary-list__value", text: "Not reported")
    end

    it "renders the induction start date from the first induction period, with a hint" do
      expect(page).to have_selector(".govuk-summary-list__key", text: "Induction start date")
      expect(page).to have_selector(".govuk-summary-list__value", text: "1 September 2023This has been reported by an appropriate body")
      expect(page).not_to have_selector(".govuk-summary-list__value", text: "Yet to be reported by the appropriate body")
    end
  end
end
