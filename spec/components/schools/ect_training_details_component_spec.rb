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
                          teacher:,
                          training_programme: 'provider_led')
      end

      before do
        # Create an EOI training period that matches the ongoing scope
        active_lead_provider = FactoryBot.create(:active_lead_provider, lead_provider:)
        FactoryBot.create(:training_period,
                          :provider_led,
                          :ongoing,
                          ect_at_school_period: ect,
                          school_partnership: nil,
                          expression_of_interest: active_lead_provider,
                          started_on: Date.current,
                          finished_on: nil)
        ect.reload # Ensure association cache is cleared
        render_inline(described_class.new(ect))
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

    before do
      # Create a school-led training period since the factory doesn't create one automatically for school-led
      FactoryBot.create(:training_period,
                        :school_led,
                        :ongoing,
                        ect_at_school_period: ect,
                        started_on: Date.current,
                        finished_on: nil)
      render_inline(described_class.new(ect))
    end

    it "does not show lead provider and delivery partner fields" do
      expect(page).not_to have_selector('.govuk-summary-list__key', text: 'Lead provider')
      expect(page).not_to have_selector('.govuk-summary-list__key', text: 'Delivery partner')
    end
  end

  describe '#training_programme_display_name' do
    context 'when training programme is provider_led' do
      let(:ect) do
        FactoryBot.create(:ect_at_school_period,
                          :ongoing,
                          :with_training_period,
                          teacher:,
                          training_programme: 'provider_led')
      end
      let(:component) { described_class.new(ect) }

      it 'returns Provider-led' do
        expect(component.send(:training_programme_display_name)).to eq('Provider-led')
      end
    end

    context 'when training programme is school_led' do
      let(:ect) do
        FactoryBot.create(:ect_at_school_period,
                          :ongoing,
                          teacher:,
                          training_programme: 'school_led')
      end
      let(:component) { described_class.new(ect) }

      before do
        # Create a school-led training period that matches the ongoing scope
        FactoryBot.create(:training_period,
                          :school_led,
                          :ongoing,
                          ect_at_school_period: ect,
                          started_on: Date.current,
                          finished_on: nil)
        ect.reload # Ensure association cache is cleared
      end

      it 'returns School-led' do
        expect(component.send(:training_programme_display_name)).to eq('School-led')
      end
    end

    context 'when training programme is an unknown value' do
      it 'returns the humanized value' do
        ect_double = instance_double(ECTAtSchoolPeriod)
        training_period_double = instance_double(TrainingPeriod)

        allow(ect_double).to receive(:current_training_period).and_return(training_period_double)
        allow(training_period_double).to receive(:training_programme).and_return('some_other_value')

        component = described_class.new(ect_double)

        expect(component.send(:training_programme_display_name)).to eq('Some other value')
      end
    end

    context 'when training programme is nil' do
      it 'returns Unknown' do
        ect_double = instance_double(ECTAtSchoolPeriod)

        allow(ect_double).to receive(:current_training_period).and_return(nil)

        component = described_class.new(ect_double)

        expect(component.send(:training_programme_display_name)).to eq('Unknown')
      end
    end
  end
end
