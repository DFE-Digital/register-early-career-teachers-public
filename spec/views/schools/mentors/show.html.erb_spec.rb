RSpec.describe "schools/mentors/show.html.erb" do
  let(:school)      { FactoryBot.create(:school) }
  let(:start_date)  { Date.new(2023, 9, 1) }

  let(:mentor_teacher) do
    FactoryBot.create(
      :teacher,
      trs_first_name: "Naruto",
      trs_last_name: "Uzumaki",
      mentor_became_ineligible_for_funding_on:,
      mentor_became_ineligible_for_funding_reason:
    )
  end
  let(:mentor_became_ineligible_for_funding_on) { nil }
  let(:mentor_became_ineligible_for_funding_reason) { nil }

  let(:mentor_period) do
    FactoryBot.create(:mentor_at_school_period, teacher: mentor_teacher, school:, started_on: start_date, finished_on: nil)
  end

  let(:ects) { [] }

  let(:lead_provider)                  { FactoryBot.create(:lead_provider, name: "Hidden leaf village") }
  let(:active_lead_provider)           { FactoryBot.create(:active_lead_provider, lead_provider:) }
  let(:lead_provider_delivery_partner) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:) }
  let(:school_partnership)             { FactoryBot.create(:school_partnership, lead_provider_delivery_partnership: lead_provider_delivery_partner, school:) }

  def render_view
    assign(:mentor, mentor_period)
    assign(:teacher, mentor_teacher)
    assign(:ects, ects)
    render
  end

  context "when mentor is not registered for training" do
    before { render_view }

    it "renders the section and message but no list" do
      expect(rendered).to have_css("h2.govuk-heading-m", text: "ECTE mentor training details")
      expect(rendered).to have_css(".govuk-body", text: "Naruto Uzumaki is not currently registered for ECTE mentor training with a lead provider.")
      expect(rendered).not_to have_css("dt.govuk-summary-list__key", text: "Lead provider")
      expect(rendered).not_to have_css("dt.govuk-summary-list__key", text: "Delivery partner")
    end
  end

  context "when mentor is eligible via EOI (awaiting confirmation)" do
    before do
      FactoryBot.create(
        :training_period, :provider_led, :for_mentor, :with_no_school_partnership,
        mentor_at_school_period: mentor_period,
        started_on: start_date, finished_on: nil,
        expression_of_interest: active_lead_provider
      )
      render_view
    end

    it "shows the ECTE mentor training details heading" do
      expect(rendered).to have_css("h2.govuk-heading-m", text: "ECTE mentor training details")
    end

    it "shows the lead provider and 'Awaiting confirmation' hint" do
      expect(rendered).to have_css("dt.govuk-summary-list__key", text: "Lead provider")
      expect(rendered).to have_text("Hidden leaf village")
      expect(rendered).to have_css(".govuk-hint", text: /Awaiting confirmation by Hidden leaf village/)
    end

    it "shows the delivery partner as 'Yet to be reported by the lead provider'" do
      expect(rendered).to have_css("dt.govuk-summary-list__key", text: "Delivery partner")
      expect(rendered).to have_text("Yet to be reported by the lead provider")
    end
  end

  context "when mentor has a confirmed partnership" do
    before do
      FactoryBot.create(
        :training_period, :provider_led, :for_mentor,
        mentor_at_school_period: mentor_period,
        started_on: start_date, finished_on: nil,
        school_partnership:
      )
      render_view
    end

    it "shows the lead provider with a 'Confirmed by' hint" do
      expect(rendered).to have_css(".govuk-hint", text: /Confirmed by Hidden leaf village/)
    end

    it "shows the delivery partner and the change-DP hint" do
      dp_name = lead_provider_delivery_partner.delivery_partner.name
      expect(rendered).to have_css("dt.govuk-summary-list__key", text: "Delivery partner")
      expect(rendered).to have_text(dp_name)
      expect(rendered).to have_css(".govuk-hint", text: /To change the delivery partner, you must contact the lead provider/)
    end
  end

  context "when mentor is not eligible (completed)" do
    let(:mentor_became_ineligible_for_funding_on) { Date.new(2024, 1, 1) }
    let(:mentor_became_ineligible_for_funding_reason) { "completed_declaration_received" }

    before { render_view }

    it "shows the completed message with GOV.UK date and hides the summary list" do
      expect(rendered).to have_css("h2.govuk-heading-m", text: "ECTE mentor training details")
      expect(rendered).to have_css(".govuk-body", text: "Naruto Uzumaki completed mentor training on 1 January 2024.")
      expect(rendered).not_to have_css("dt.govuk-summary-list__key", text: "Lead provider")
      expect(rendered).not_to have_css("dt.govuk-summary-list__key", text: "Delivery partner")
    end
  end

  context "when mentor is not eligible (not completed)" do
    let(:mentor_became_ineligible_for_funding_on) { Date.new(2024, 1, 1) }
    let(:mentor_became_ineligible_for_funding_reason) { "started_not_completed" }

    before { render_view }

    it "shows the completed message with GOV.UK date and hides the summary list" do
      expect(rendered).to have_css("h2.govuk-heading-m", text: "ECTE mentor training details")
      expect(rendered).to have_css(".govuk-body", text: "Our records show that Naruto Uzumaki cannot do further mentor training.")
      expect(rendered).not_to have_css("dt.govuk-summary-list__key", text: "Lead provider")
      expect(rendered).not_to have_css("dt.govuk-summary-list__key", text: "Delivery partner")
    end
  end

  context "when the training period is deferred" do
    before do
      FactoryBot.create(
        :training_period, :provider_led, :for_mentor, :deferred,
        mentor_at_school_period: mentor_period,
        started_on: start_date, finished_on: nil,
        school_partnership:
      )
      render_view
    end

    it "shows the deferred message and hides the summary list" do
      expect(rendered).to have_css("h2.govuk-heading-m", text: "ECTE mentor training details")
      expect(rendered).to have_css(".govuk-body", text: "Hidden leaf village have told us that Naruto Uzumaki is not registered for ECTE mentor training with them.")
      expect(rendered).not_to have_css("dt.govuk-summary-list__key", text: "Lead provider")
      expect(rendered).not_to have_css("dt.govuk-summary-list__key", text: "Delivery partner")
    end
  end

  context "when the training period has been withdrawn" do
    before do
      FactoryBot.create(
        :training_period, :provider_led, :for_mentor, :withdrawn,
        mentor_at_school_period: mentor_period,
        started_on: start_date, finished_on: nil,
        school_partnership:
      )
      render_view
    end

    it "shows the withdrawn message and shows the summary list" do
      expect(rendered).to have_css("h2.govuk-heading-m", text: "ECTE mentor training details")
      expect(rendered).to have_css(".govuk-body", text: "Hidden leaf village have told us that Naruto Uzumaki’s ECTE mentor training is paused.")
      expect(rendered).to have_css("dt.govuk-summary-list__key", text: "Lead provider")
      expect(rendered).to have_css("dt.govuk-summary-list__key", text: "Delivery partner")
    end
  end

  context "when the training period has finished" do
    before do
      FactoryBot.create(
        :training_period, :provider_led, :for_mentor,
        mentor_at_school_period: mentor_period,
        started_on: start_date, finished_on: Date.yesterday,
        school_partnership:
      )
      render_view
    end

    it "does not render the section" do
      expect(rendered).not_to have_css("h2.govuk-heading-m", text: "ECTE mentor training details")
      expect(rendered).not_to have_css("dt.govuk-summary-list__key", text: "Lead provider")
      expect(rendered).not_to have_css("dt.govuk-summary-list__key", text: "Delivery partner")
    end
  end
end
