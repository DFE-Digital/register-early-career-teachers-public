RSpec.describe Schools::ECTTrainingDetailsComponent, type: :component do
  let(:lead_provider) { FactoryBot.create(:lead_provider, name: 'Ambition Institute') }
  let(:delivery_partner) { FactoryBot.create(:delivery_partner, name: 'Test Delivery Partner') }
  let(:teacher) { FactoryBot.create(:teacher, trn: '9876543', trs_first_name: 'John', trs_last_name: 'Doe') }
  let(:ect) do
    FactoryBot.create(:ect_at_school_period,
                      teacher:,
                      training_programme: 'provider_led')
  end

  before do
    render_inline(described_class.new(ect))
  end

  it "renders the section heading" do
    expect(page).to have_selector('h2.govuk-heading-m', text: 'Training details')
  end

  it "renders the training programme row" do
    expect(page).to have_selector('.govuk-summary-list__key', text: 'Training programme')
  end

  context 'when provider-led training' do
    let(:ect) do
      FactoryBot.create(:ect_at_school_period,
                        :ongoing,
                        :with_training_period,
                        teacher:,
                        training_programme: 'provider_led',
                        lead_provider:,
                        delivery_partner:)
    end

    it "shows lead provider and delivery partner fields" do
      expect(page).to have_selector('.govuk-summary-list__key', text: 'Lead provider')
      expect(page).to have_selector('.govuk-summary-list__key', text: 'Delivery partner')
    end

    context 'with confirmed partnership' do
      it "shows lead provider information" do
        expect(page).to have_selector('.govuk-summary-list__key', text: 'Lead provider')
        expect(page).to have_selector('.govuk-summary-list__value')
      end
    end

    context 'with expression of interest only' do
      let(:ect) do
        FactoryBot.create(:ect_at_school_period,
                          :ongoing,
                          :with_eoi_only_training_period,
                          teacher:,
                          training_programme: 'provider_led',
                          lead_provider:)
      end

      it "shows lead provider information" do
        expect(page).to have_selector('.govuk-summary-list__key', text: 'Lead provider')
        expect(page).to have_selector('.govuk-summary-list__value')
      end

      it "shows appropriate message for delivery partner" do
        expect(page).to have_text('Yet to be reported by the lead provider')
      end
    end
  end

  context 'when school-led training' do
    let(:ect) do
      FactoryBot.create(:ect_at_school_period,
                        :ongoing,
                        teacher:,
                        training_programme: 'school_led')
    end

    it "does not show lead provider and delivery partner fields" do
      expect(page).not_to have_selector('.govuk-summary-list__key', text: 'Lead provider')
      expect(page).not_to have_selector('.govuk-summary-list__key', text: 'Delivery partner')
    end
  end
end
