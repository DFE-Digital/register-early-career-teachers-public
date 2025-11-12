RSpec.shared_examples "a use previous ect choices view" do |current_step:, back_path:, back_step_name:, continue_path:, continue_step_name:|
  let(:last_chosen_appropriate_body) { FactoryBot.build(:appropriate_body) }
  let(:last_chosen_lead_provider) { FactoryBot.build(:lead_provider) }
  let(:last_chosen_delivery_partner) { FactoryBot.build(:delivery_partner) }

  let(:store) do
    FactoryBot.build(
      :session_repository,
      full_name: "John Doe",
      trn: "123456",
      email: "foo@bar.com",
      govuk_date_of_birth: "12 January 1931",
      start_date: "September 2022",
      training_programme: "school_led",
      appropriate_body_type: "teaching_school_hub",
      appropriate_body: double(name: "Teaching Regulation Agency"),
      lead_provider: double(name: "Acme Lead Provider"),
      formatted_working_pattern: "Full time",
      use_previous_ect_choices: false
    )
  end
  let(:school) { FactoryBot.create(:school, :independent) }
  let(:decorated_school) { Schools::DecoratedSchool.new(school) }
  let(:wizard) { FactoryBot.build(:register_ect_wizard, current_step:, store:, school:) }

  before do
    assign(:ect, wizard.ect)
    assign(:school, school)
    assign(:decorated_school, decorated_school)
    assign(:wizard, wizard)
  end

  it "sets the page title" do
    render
    expect(sanitize(view.content_for(:page_title))).to eql("Programme choices used by your school previously")
  end

  context "when the input data is invalid" do
    before do
      wizard.current_step.use_previous_ect_choices = nil
      wizard.valid_step?
      render
    end

    it "prefixes the page with 'Error:'" do
      expect(view.content_for(:page_title)).to start_with("Error:")
    end

    it "renders an error summary" do
      expect(view.content_for(:error_summary)).to have_css(".govuk-error-summary")
    end
  end

  it "includes a back button that targets #{back_step_name} page" do
    render
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link("Back", href: send(back_path))
  end

  it "includes a continue button that posts to the #{continue_step_name} page" do
    render
    expect(rendered).to have_button("Continue")
    expect(rendered).to have_selector("form[action='#{send(continue_path)}']")
  end

  context "when school-led" do
    let(:appropriate_body) { FactoryBot.create(:appropriate_body, :teaching_school_hub, name: "Team 7") }
    let(:school) do
      FactoryBot.create(
        :school,
        :school_led_last_chosen,
        last_chosen_appropriate_body: appropriate_body
      )
    end

    before do
      assign(:school, school)
      assign(:decorated_school, decorated_school)
      render
    end

    it "renders the appropriate body row" do
      expect(rendered).to have_css(".govuk-summary-list__key", text: "Appropriate body")
      expect(rendered).to have_css(".govuk-summary-list__value", text: "Team 7")
    end

    it "renders the training programme row" do
      expect(rendered).to have_css(".govuk-summary-list__key", text: "Training programme")
      expect(rendered).to have_css(".govuk-summary-list__value", text: "School-led")
    end

    it "does not render the lead provider row" do
      expect(rendered).not_to have_css(".govuk-summary-list__key", text: "Lead provider")
    end

    it "does not render the delivery partner row" do
      expect(rendered).not_to have_css(".govuk-summary-list__key", text: "Delivery partner")
    end
  end

  context "when provider-led with confirmed partnership" do
    let(:school) { FactoryBot.create(:school, :provider_led_last_chosen) }

    before do
      choices = double(
        "Schools::LatestRegistrationChoices",
        lead_provider: last_chosen_lead_provider,
        delivery_partner: last_chosen_delivery_partner,
        appropriate_body: last_chosen_appropriate_body
      )

      allow(decorated_school).to receive(:latest_registration_choices).and_return(choices)

      assign(:school, school)
      assign(:decorated_school, decorated_school)
      render
    end

    it "renders the lead provider row" do
      expect(rendered).to have_css(".govuk-summary-list__key", text: "Lead provider")
      expect(rendered).to have_css(".govuk-summary-list__value", text: last_chosen_lead_provider.name)
    end

    it "renders the delivery partner row" do
      expect(rendered).to have_css(".govuk-summary-list__key", text: "Delivery partner")
      expect(rendered).to have_css(".govuk-summary-list__value", text: last_chosen_delivery_partner.name)
    end
  end

  context "when provider-led with expression of interest only" do
    let(:school) { FactoryBot.create(:school, :provider_led_last_chosen) }
    let(:contract_start_date) { Date.new(2025, 9, 1) }

    before do
      # ensure a valid contract period includes that date
      FactoryBot.create(
        :contract_period,
        started_on: Date.new(2025, 9, 1),
        finished_on: Date.new(2026, 8, 31),
        enabled: true
      )

      choices = double(
        "Schools::LatestRegistrationChoices",
        lead_provider: last_chosen_lead_provider,
        appropriate_body: last_chosen_appropriate_body,
        delivery_partner: nil
      )

      allow(decorated_school).to receive_messages(
        latest_registration_choices: choices,
        has_partnership_with?: false
      )

      allow(wizard.ect).to receive(:contract_start_date).and_return(contract_start_date)

      assign(:school, school)
      assign(:decorated_school, decorated_school)
      render
    end

    it "renders the lead provider row with the EOI name" do
      expect(rendered).to have_css(".govuk-summary-list__key", text: "Lead provider")
      expect(rendered).to have_css(".govuk-summary-list__value", text: last_chosen_lead_provider.name)
    end

    it "does not render the delivery partner row" do
      expect(rendered).not_to have_css(".govuk-summary-list__key", text: "Delivery partner")
    end

    it "renders the explanatory paragraph" do
      expect(rendered).to include("#{last_chosen_lead_provider.name} will confirm if they’ll be working with your school and which delivery partner will deliver training events.")
    end

    it "calls #has_partnership_with? using the lead provider and contract period" do
      expect(decorated_school).to have_received(:has_partnership_with?).with(
        lead_provider: decorated_school.latest_registration_choices.lead_provider,
        contract_period: contract_start_date
      )
    end
  end
end
