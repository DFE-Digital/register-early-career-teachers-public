RSpec.describe Admin::Teachers::UndoRegistrationWizard::SchoolPeriodSummaryComponent, type: :component do
  subject(:rendered) do
    render_inline(described_class.new(school_period:, end_date:))
    page
  end

  let(:school) { FactoryBot.create(:school) }
  let(:started_on) { Date.new(2025, 9, 1) }
  let(:end_date) { Date.new(2026, 9, 18) }

  context "with an ECT school period" do
    let(:appropriate_body) { FactoryBot.create(:appropriate_body_period, name: "Appropriate Body Name") }
    let(:school_period) do
      FactoryBot.create(
        :ect_at_school_period,
        school:,
        school_reported_appropriate_body: appropriate_body,
        started_on:
      )
    end

    it "uses the school name as the card title" do
      expect(rendered).to have_css(
        "h4.govuk-summary-card__title",
        text: school.name
      )
    end

    it "shows the school period type" do
      expect(rendered).to have_summary_list_row("School period type", value: "ECT")
    end

    it "shows the school URN" do
      expect(rendered).to have_summary_list_row("School URN", value: school.urn)
    end

    it "shows the appropriate body" do
      expect(rendered).to have_summary_list_row("Appropriate body", value: appropriate_body.name)
    end

    it "shows the school start date" do
      expect(rendered).to have_summary_list_row("School start date", value: started_on.to_fs(:govuk))
    end

    it "shows the end date" do
      expect(rendered).to have_summary_list_row("End date", value: end_date.to_fs(:govuk))
    end

    context "without an appropriate body" do
      let(:appropriate_body) { nil }

      it "shows that the appropriate body is not available" do
        expect(rendered).to have_summary_list_row("Appropriate body", value: "Not available")
      end
    end
  end

  context "with a mentor school period" do
    let(:school_period) { FactoryBot.create(:mentor_at_school_period) }

    it "shows the school period type" do
      expect(rendered).to have_summary_list_row("School period type", value: "Mentor")
    end

    it "does not show an appropriate body" do
      expect(rendered).not_to have_summary_list_row("Appropriate body")
    end
  end

  context "without an end date" do
    let(:school_period) do
      FactoryBot.create(
        :ect_at_school_period,
        :unfinished,
        school:,
        started_on:
      )
    end
    let(:end_date) { nil }

    it "shows that no end date is recorded" do
      expect(rendered).to have_summary_list_row("End date", value: "No end date recorded")
    end
  end
end
