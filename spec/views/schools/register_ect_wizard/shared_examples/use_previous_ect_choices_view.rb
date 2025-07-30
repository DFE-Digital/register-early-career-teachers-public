RSpec.shared_examples "a use previous ect choices view" do |current_step:, back_path:, back_step_name:, continue_path:, continue_step_name:|
  let(:store) do
    FactoryBot.build(:session_repository,
                     full_name: 'John Doe',
                     trn: '123456',
                     email: 'foo@bar.com',
                     govuk_date_of_birth: '12 January 1931',
                     start_date: 'September 2022',
                     training_programme: 'school_led',
                     appropriate_body_type: 'teaching_school_hub',
                     appropriate_body: double(name: 'Teaching Regulation Agency'),
                     lead_provider: double(name: 'Acme Lead Provider'),
                     formatted_working_pattern: 'Full time',
                     use_previous_ect_choices: false)
  end
  let(:school) { FactoryBot.create(:school, :independent) }
  let(:wizard) { FactoryBot.build(:register_ect_wizard, current_step:, store:, school:) }

  before do
    assign(:ect, wizard.ect)
    assign(:school, school)
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
      expect(view.content_for(:page_title)).to start_with('Error:')
    end

    it 'renders an error summary' do
      expect(view.content_for(:error_summary)).to have_css('.govuk-error-summary')
    end
  end

  it "includes a back button that targets #{back_step_name} page" do
    render

    expect(view.content_for(:backlink_or_breadcrumb)).to have_link('Back', href: send(back_path))
  end

  it "includes a continue button that posts to the #{continue_step_name} page" do
    render

    expect(rendered).to have_button('Continue')
    expect(rendered).to have_selector("form[action='#{send(continue_path)}']")
  end

  context "when school-led" do
    let(:appropriate_body) { FactoryBot.create(:appropriate_body, :teaching_school_hub, name: 'Team 7') }
    let(:school) do
      FactoryBot.create(
        :school,
        :school_led_last_chosen,
        last_chosen_appropriate_body: appropriate_body
      )
    end

    before do
      assign(:school, school)
      render
    end

    it 'renders the appropriate body row' do
      expect(rendered).to have_css('.govuk-summary-list__key', text: 'Appropriate body')
      expect(rendered).to have_css('.govuk-summary-list__value', text: 'Team 7')
    end

    it 'renders the training programme row' do
      expect(rendered).to have_css('.govuk-summary-list__key', text: 'Training programme')
      expect(rendered).to have_css('.govuk-summary-list__value', text: 'School-led')
    end

    it 'does not render the lead provider row' do
      expect(rendered).not_to have_css('.govuk-summary-list__key', text: 'Lead provider')
    end

    it 'does not render the delivery partner row' do
      expect(rendered).not_to have_css('.govuk-summary-list__key', text: 'Delivery partner')
    end
  end

  context 'when provider-led with confirmed partnership' do
    let(:school) { FactoryBot.create(:school, :provider_led_last_chosen) }

    before do
      allow(wizard.ect).to receive(:lead_provider_has_confirmed_partnership_for_contract_period?).with(school).and_return(true)
      allow(wizard.ect).to receive_messages(
        previous_lead_provider_name: 'Orochimaru',
        previous_delivery_partner_name: 'Akatsuki'
      )

      assign(:school, school)
      render
    end

    it 'renders the lead provider row' do
      expect(rendered).to have_css('.govuk-summary-list__key', text: 'Lead provider')
      expect(rendered).to have_css('.govuk-summary-list__value', text: 'Orochimaru')
    end

    it 'renders the delivery partner row' do
      expect(rendered).to have_css('.govuk-summary-list__key', text: 'Delivery partner')
      expect(rendered).to have_css('.govuk-summary-list__value', text: 'Akatsuki')
    end
  end

  context 'when provider-led with expression of interest only' do
    let(:school) { FactoryBot.create(:school, :provider_led_last_chosen) }

    before do
      allow(wizard.ect).to receive(:lead_provider_has_confirmed_partnership_for_contract_period?).with(school).and_return(false)
      allow(wizard.ect).to receive(:previous_eoi_lead_provider_name).and_return('Uchiha Clan')

      assign(:school, school)
      render
    end

    it 'renders the lead provider row with the EOI name' do
      expect(rendered).to have_css('.govuk-summary-list__key', text: 'Lead provider')
      expect(rendered).to have_css('.govuk-summary-list__value', text: 'Uchiha Clan')
    end

    it 'does not render the delivery partner row' do
      expect(rendered).not_to have_css('.govuk-summary-list__key', text: 'Delivery partner')
    end

    it 'renders the explanatory paragraph' do
      expect(rendered).to include('Uchiha Clan will confirm if they’ll be working with your school and which delivery partner will deliver training events.')
    end
  end
end
