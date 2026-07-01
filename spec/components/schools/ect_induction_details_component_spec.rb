RSpec.describe Schools::ECTInductionDetailsComponent, type: :component do
  include Rails.application.routes.url_helpers

  let(:awaiting_confirmation_hint) { "Awaiting confirmation by the appropriate body" }
  let(:confirmed_hint) { "This appropriate body has recorded the ECT’s induction." }

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

  describe "change appropriate body link" do
    context "when the teacher does not have an ongoing induction period" do
      it "renders the change link for the appropriate body" do
        expect(page).to have_link("Change", href: schools_ects_change_appropriate_body_wizard_edit_path(ect_id: ect.id))
      end
    end

    context "when the teacher has an ongoing induction period" do
      before do
        FactoryBot.create(:induction_period, :ongoing, teacher:, appropriate_body_period:)
        teacher.reload
        render_inline(described_class.new(ect))
      end

      it "does not render the change link for the appropriate body" do
        expect(page).not_to have_link("Change")
      end
    end

    context "when the teacher has a finished induction period" do
      before do
        FactoryBot.create(:induction_period, teacher:, appropriate_body_period:)
        teacher.reload
        render_inline(described_class.new(ect))
      end

      it "renders the change link for the appropriate body" do
        expect(page).to have_link("Change", href: schools_ects_change_appropriate_body_wizard_edit_path(ect_id: ect.id))
      end
    end
  end

  describe "appropriate body status" do
    context "when the school reported appropriate body has not claimed the induction" do
      it "shows the awaiting confirmation hint" do
        expect(page).to have_selector(".govuk-summary-list__value", text: "Alpha Teaching School Hub")
        expect(page).to have_text(awaiting_confirmation_hint)
        expect(page).not_to have_text(confirmed_hint)
      end
    end

    context "when the school reported appropriate body has claimed the induction" do
      let!(:induction_period) do
        FactoryBot.create(:induction_period, :ongoing, teacher:, appropriate_body_period:, started_on: Date.new(2023, 9, 1))
      end

      before do
        teacher.reload
        render_inline(described_class.new(ect))
      end

      it "shows the confirmed hint" do
        expect(page).to have_selector(".govuk-summary-list__value", text: "Alpha Teaching School Hub")
        expect(page).to have_text(confirmed_hint)
        expect(page).not_to have_text(awaiting_confirmation_hint)
      end
    end

    context "when an appropriate body other than the one the school reported has claimed the induction" do
      let(:other_appropriate_body_period) { FactoryBot.create(:appropriate_body_period, name: "Beta Teaching School Hub") }
      let!(:induction_period) do
        FactoryBot.create(:induction_period, :ongoing, teacher:, appropriate_body_period: other_appropriate_body_period, started_on: Date.new(2023, 9, 1))
      end

      before do
        teacher.reload
        render_inline(described_class.new(ect))
      end

      it "shows the claiming appropriate body with the confirmed hint" do
        expect(page).to have_selector(".govuk-summary-list__value", text: "Beta Teaching School Hub")
        expect(page).not_to have_selector(".govuk-summary-list__value", text: "Alpha Teaching School Hub")
        expect(page).to have_text(confirmed_hint)
        expect(page).not_to have_text(awaiting_confirmation_hint)
      end
    end

    context "when an ongoing induction period predates this school placement (claimed before registration, or carried over from a previous school)" do
      let(:other_appropriate_body_period) { FactoryBot.create(:appropriate_body_period, name: "Beta Teaching School Hub") }
      let!(:induction_period) do
        FactoryBot.create(:induction_period, :ongoing, teacher:, appropriate_body_period: other_appropriate_body_period, started_on: Date.new(2022, 9, 1))
      end

      before do
        teacher.reload
        render_inline(described_class.new(ect))
      end

      it "still shows the school reported appropriate body with the awaiting confirmation hint" do
        expect(page).to have_selector(".govuk-summary-list__value", text: "Alpha Teaching School Hub")
        expect(page).not_to have_selector(".govuk-summary-list__value", text: "Beta Teaching School Hub")
        expect(page).to have_text(awaiting_confirmation_hint)
        expect(page).not_to have_text(confirmed_hint)
      end
    end
  end
end
