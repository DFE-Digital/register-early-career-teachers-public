RSpec.describe Admin::Teachers::UndoRegistrationWizard::SchoolPeriodSummaryComponent, type: :component do
  subject(:rendered) { render_inline(described_class.new(school_period:, end_date:)) }

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
      expect(rendered).to have_css("dt", text: "School period type")
      expect(rendered).to have_css("dd", text: "ECT")
    end

    it "shows the school URN" do
      expect(rendered).to have_css("dt", text: "School URN")
      expect(rendered).to have_css("dd", text: school.urn)
    end

    it "shows the appropriate body" do
      expect(rendered).to have_css("dt", text: "Appropriate body")
      expect(rendered).to have_css("dd", text: appropriate_body.name)
    end

    it "shows the school start date" do
      expect(rendered).to have_css("dt", text: "School start date")
      expect(rendered).to have_css("dd", text: started_on.to_fs(:govuk))
    end

    it "shows the end date" do
      expect(rendered).to have_css("dt", text: "End date")
      expect(rendered).to have_css("dd", text: end_date.to_fs(:govuk))
    end

    context "without an appropriate body" do
      let(:appropriate_body) { nil }

      it "shows that the appropriate body is not available" do
        expect(rendered).to have_css("dt", text: "Appropriate body")
        expect(rendered).to have_css("dd", text: "Not available")
      end
    end
  end

  context "with a mentor school period" do
    let(:school_period) { FactoryBot.create(:mentor_at_school_period) }

    it "shows the school period type" do
      expect(rendered).to have_css("dt", text: "School period type")
      expect(rendered).to have_css("dd", text: "Mentor")
    end

    it "does not show an appropriate body" do
      expect(rendered).not_to have_css("dt", text: "Appropriate body")
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
      expect(rendered).to have_css("dt", text: "End date")
      expect(rendered).to have_css("dd", text: "No end date recorded")
    end
  end
end
