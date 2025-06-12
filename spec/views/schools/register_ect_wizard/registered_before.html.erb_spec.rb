RSpec.describe 'schools/register_ect_wizard/registered_before.html.erb' do
  let(:school) { FactoryBot.create(:school) }
  let(:teacher) { FactoryBot.create(:teacher) }
  let(:delivery_partner) { FactoryBot.create(:delivery_partner) }
  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }
  let(:lead_provider) { FactoryBot.create(:lead_provider, name: "Confirmed LP") }
  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, lead_provider:) }
  let(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, delivery_partner:, active_lead_provider:) }
  let(:school_partnership) { FactoryBot.create(:school_partnership, lead_provider_delivery_partnership:) }

  let(:ect_at_school_period) do
    FactoryBot.create(
      :ect_at_school_period,
      finished_on: nil,
      school:,
      teacher:,
      started_on: Date.new(2023, 9, 1),
      programme_type: 'provider_led'
    )
  end

  let(:store) do
    FactoryBot.build(
      :session_repository,
      trs_first_name: 'Konohamaru',
      trs_last_name: 'Sarutobi',
      ect_at_school_period_id: ect_at_school_period.id,
      trn: teacher.trn
    )
  end

  let(:wizard) do
    FactoryBot.build(
      :register_ect_wizard,
      current_step: :registered_before,
      school:,
      store:
    )
  end

  let(:wizard_ect) { Schools::RegisterECTWizard::ECT.new(store) }

  before do
    FactoryBot.create(
      :training_period,
      ect_at_school_period:,
      started_on: Date.new(2023, 9, 1),
      finished_on: Date.new(2024, 7, 31),
      school_partnership:
    )

    FactoryBot.create(
      :induction_period,
      teacher:,
      appropriate_body:,
      started_on: Date.new(2023, 9, 1),
      finished_on: Date.new(2024, 7, 31)
    )

    FactoryBot.create(:gias_school, school:, name: "Really cool school")

    assign(:school, school)
    assign(:ect, wizard_ect)
    assign(:wizard, wizard)
    render
  end

  context 'Provider-led' do
    it 'renders the full name in the page title' do
      expect(view.content_for(:page_title)).to include('Konohamaru Sarutobi has been registered before')
    end

    it 'shows the previously used school name' do
      expect(rendered).to have_css('dt.govuk-summary-list__key', text: 'School name')
      expect(rendered).to have_css('dd.govuk-summary-list__value', text: 'Really cool school')
    end

    it 'shows the previously used induction start date' do
      expect(rendered).to have_css('dt.govuk-summary-list__key', text: 'Induction start date')
      expect(rendered).to have_css('dd.govuk-summary-list__value', text: '1 September 2023')
    end

    it 'shows the previously used appropriate body' do
      expect(rendered).to have_css('dt.govuk-summary-list__key', text: 'Appropriate body')
      expect(rendered).to have_css('dd.govuk-summary-list__value', text: appropriate_body.name)
    end

    it 'shows the previously used training programme' do
      expect(rendered).to have_css('dt.govuk-summary-list__key', text: 'Training programme')
      expect(rendered).to have_css('dd.govuk-summary-list__value', text: 'Provider-led')
    end

    it 'shows the previously used lead provider' do
      expect(rendered).to have_css('dt.govuk-summary-list__key', text: 'Lead provider')
      expect(rendered).to have_css('dd.govuk-summary-list__value', text: 'Confirmed LP')
    end

    it 'shows the previously used delivery partner' do
      expect(rendered).to have_css('dt.govuk-summary-list__key', text: 'Delivery partner')
      expect(rendered).to have_css('dd.govuk-summary-list__value', text: delivery_partner.name)
    end
  end

  context 'School-led' do
    let(:ect_at_school_period) do
      FactoryBot.create(
        :ect_at_school_period,
        started_on: Date.new(2023, 9, 1),
        finished_on: nil,
        school:,
        teacher:,
        programme_type: 'school_led',
        lead_provider_id: nil
      )
    end

    it 'renders the full name in the page title' do
      expect(view.content_for(:page_title)).to include('Konohamaru Sarutobi has been registered before')
    end

    it 'shows the previously used school name' do
      expect(rendered).to have_css('dt.govuk-summary-list__key', text: 'School name')
      expect(rendered).to have_css('dd.govuk-summary-list__value', text: 'Really cool school')
    end

    it 'shows the previously used induction start date' do
      expect(rendered).to have_css('dt.govuk-summary-list__key', text: 'Induction start date')
      expect(rendered).to have_css('dd.govuk-summary-list__value', text: '1 September 2023')
    end

    it 'shows the previously used appropriate body' do
      expect(rendered).to have_css('dt.govuk-summary-list__key', text: 'Appropriate body')
      expect(rendered).to have_css('dd.govuk-summary-list__value', text: appropriate_body.name)
    end

    it 'shows the previously used training programme' do
      expect(rendered).to have_css('dt.govuk-summary-list__key', text: 'Training programme')
      expect(rendered).to have_css('dd.govuk-summary-list__value', text: 'School-led')
    end

    it 'does not show the previously used lead provider' do
      expect(rendered).not_to have_css('dt.govuk-summary-list__key', text: 'Lead provider')
    end

    it 'does not show the previously used delivery partner' do
      expect(rendered).not_to have_css('dt.govuk-summary-list__key', text: 'Delivery partner')
      expect(rendered).not_to have_css('dd.govuk-summary-list__value', text: delivery_partner.name)
    end
  end
end
