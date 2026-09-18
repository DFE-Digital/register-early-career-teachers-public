RSpec.describe Admin::Teachers::UndoRegistrationWizard::TrainingPeriodSummaryComponent, type: :component do
  subject(:rendered) { render_inline(described_class.new(training_period:, end_date:)) }

  let(:end_date) { Date.new(2026, 9, 17) }
  let(:started_on) { Date.new(2025, 9, 1) }
  let(:at_school_period) { FactoryBot.create(:ect_at_school_period, :unfinished, started_on:) }

  context "with a confirmed provider-led training period" do
    let(:training_period) do
      FactoryBot.create(
        :training_period,
        :for_ect,
        :provider_led,
        ect_at_school_period: at_school_period,
        started_on:
      )
    end

    it "uses the partnership as the card title" do
      expect(rendered).to have_css(
        "h4.govuk-summary-card__title",
        text: "#{training_period.lead_provider_name} & #{training_period.delivery_partner_name}"
      )
    end

    it "shows the lead provider" do
      expect(rendered).to have_css("dt", text: "Lead provider")
      expect(rendered).to have_css("dd", text: training_period.lead_provider_name)
    end

    it "shows the delivery partner" do
      expect(rendered).to have_css("dt", text: "Delivery partner")
      expect(rendered).to have_css("dd", text: training_period.delivery_partner_name)
    end

    it "shows the contract period" do
      expect(rendered).to have_css("dt", text: "Contract period")
      expect(rendered).to have_css("dd", exact_text: training_period.contract_period.year.to_s)
    end

    it "shows the schedule" do
      expect(rendered).to have_css("dt", text: "Schedule")
      expect(rendered).to have_css("dd", text: training_period.schedule.identifier)
    end

    it "shows the start date" do
      expect(rendered).to have_css("dt", text: "Start date")
      expect(rendered).to have_css("dd", text: started_on.to_fs(:govuk))
    end

    it "shows the end date" do
      expect(rendered).to have_css("dt", text: "End date")
      expect(rendered).to have_css("dd", text: end_date.to_fs(:govuk))
    end

    it "does not show actions" do
      expect(rendered).not_to have_link("Change")
    end
  end

  context "with an expression of interest" do
    let(:training_period) do
      FactoryBot.create(
        :training_period,
        :for_ect,
        :provider_led,
        :with_only_expression_of_interest,
        ect_at_school_period: at_school_period,
        started_on:
      )
    end

    it "uses the expression of interest lead provider as the card title" do
      expect(rendered).to have_css(
        "h4.govuk-summary-card__title",
        text: training_period.expression_of_interest_lead_provider.name
      )
    end

    it "shows the expression of interest lead provider" do
      expect(rendered).to have_css("dt", text: "Lead provider")
      expect(rendered).to have_css("dd", text: training_period.expression_of_interest_lead_provider.name)
    end

    it "shows that there is no confirmed delivery partner" do
      expect(rendered).to have_css("dt", text: "Delivery partner")
      expect(rendered).to have_css("dd", text: "No delivery partner confirmed")
    end

    it "shows the expression of interest contract period" do
      expect(rendered).to have_css("dt", text: "Contract period")
      expect(rendered).to have_css("dd", exact_text: training_period.expression_of_interest_contract_period.year.to_s)
    end
  end

  context "with a school-led training period" do
    let(:training_period) do
      FactoryBot.create(
        :training_period,
        :for_ect,
        :school_led,
        ect_at_school_period: at_school_period,
        started_on:
      )
    end

    it "uses the training programme as the card title" do
      expect(rendered).to have_css(
        "h4.govuk-summary-card__title",
        text: "School-led training programme"
      )
    end

    it "shows the start date" do
      expect(rendered).to have_css("dt", text: "Start date")
      expect(rendered).to have_css("dd", text: started_on.to_fs(:govuk))
    end

    it "shows the end date" do
      expect(rendered).to have_css("dt", text: "End date")
      expect(rendered).to have_css("dd", text: end_date.to_fs(:govuk))
    end

    it "does not show provider details" do
      expect(rendered).not_to have_css("dt", text: "Lead provider")
    end
  end

  context "without an end date" do
    let(:training_period) do
      FactoryBot.create(
        :training_period,
        :for_ect,
        :school_led,
        :unfinished,
        ect_at_school_period: at_school_period,
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
