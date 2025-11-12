RSpec.describe Schools::RegisterECTWizard::RegistrationStore::PreviousRegistration do
  subject(:previous_registration) { described_class.new(registration_store:, queries:) }

  let(:registration_store) { instance_double(Schools::RegisterECTWizard::RegistrationStore) }
  let(:queries) { instance_double(Schools::RegisterECTWizard::RegistrationStore::Queries) }

  let(:previous_ect_period) { nil }
  let(:previous_training_period) { nil }
  let(:previous_appropriate_body) { nil }
  let(:previous_delivery_partner) { nil }
  let(:previous_lead_provider) { nil }

  before do
    allow(queries).to receive_messages(previous_ect_at_school_period: previous_ect_period, previous_training_period:, previous_appropriate_body:, previous_delivery_partner:, previous_lead_provider:)
  end

  describe '#present?' do
    context 'when there is a previous ECT period' do
      let(:previous_ect_period) { instance_double(ECTAtSchoolPeriod) }

      it 'returns true' do
        expect(previous_registration.present?).to be(true)
      end
    end

    context 'when there is no previous ECT period' do
      it 'returns false' do
        expect(previous_registration.present?).to be(false)
      end
    end
  end

  describe '#previous_school_name' do
    let(:previous_ect_period) { instance_double(ECTAtSchoolPeriod, school:) }

    context 'when a previous school exists' do
      let(:school) { instance_double(School, name: 'Springfield Elementary') }

      it 'returns the school name' do
        expect(previous_registration.previous_school_name).to eq('Springfield Elementary')
      end
    end

    context 'when there is no previous school' do
      let(:school) { nil }

      it 'returns nil' do
        expect(previous_registration.previous_school_name).to be_nil
      end
    end
  end

  describe '#previous_training_programme' do
    context 'when there is a previous training period' do
      let(:previous_training_period) do
        instance_double(TrainingPeriod,
                        training_programme: 'school_led',
                        provider_led_training_programme?: provider_led)
      end
      let(:provider_led) { true }

      it 'returns the training programme' do
        expect(previous_registration.previous_training_programme).to eq('school_led')
      end

      it 'reports whether the programme was provider led' do
        expect(previous_registration.previous_provider_led?).to be(true)
      end
    end

    context 'when there is no previous training period' do
      it 'returns nil for the programme' do
        expect(previous_registration.previous_training_programme).to be_nil
      end

      it 'returns nil for provider led check' do
        expect(previous_registration.previous_provider_led?).to be_nil
      end
    end
  end

  describe '#previous_lead_provider_name' do
    context 'when a previous lead provider exists' do
      let(:previous_lead_provider) { instance_double(LeadProvider, name: 'Duff Institute') }

      it 'returns the lead provider name' do
        expect(previous_registration.previous_lead_provider_name).to eq('Duff Institute')
      end
    end

    context 'when no previous lead provider exists' do
      it 'returns nil' do
        expect(previous_registration.previous_lead_provider_name).to be_nil
      end
    end
  end

  describe '#previous_delivery_partner_name' do
    context 'when a previous delivery partner exists' do
      let(:previous_delivery_partner) { instance_double(DeliveryPartner, name: 'Evergreen Delivery') }

      it 'returns the delivery partner name' do
        expect(previous_registration.previous_delivery_partner_name).to eq('Evergreen Delivery')
      end
    end

    context 'when no previous delivery partner exists' do
      it 'returns nil' do
        expect(previous_registration.previous_delivery_partner_name).to be_nil
      end
    end
  end

  describe '#previous_appropriate_body_name' do
    context 'when a previous appropriate body exists' do
      let(:previous_appropriate_body) { instance_double(AppropriateBody, name: 'North Springfield Hub') }

      it 'returns the appropriate body name' do
        expect(previous_registration.previous_appropriate_body_name).to eq('North Springfield Hub')
      end
    end

    context 'when no previous appropriate body exists' do
      it 'returns nil' do
        expect(previous_registration.previous_appropriate_body_name).to be_nil
      end
    end
  end

  describe '#previous_eoi_lead_provider_name' do
    context 'when a previous expression of interest exists' do
      let(:previous_training_period) do
        instance_double(TrainingPeriod,
                        training_programme: 'provider_led',
                        provider_led_training_programme?: true,
                        expression_of_interest:)
      end
      let(:expression_of_interest) { instance_double(ActiveLeadProvider, lead_provider:) }
      let(:lead_provider) { instance_double(LeadProvider, name: 'Scarlet Federation') }

      it 'returns the expression of interest lead provider name' do
        expect(previous_registration.previous_eoi_lead_provider_name).to eq('Scarlet Federation')
      end
    end

    context 'when there is no expression of interest' do
      let(:previous_training_period) do
        instance_double(TrainingPeriod,
                        training_programme: 'provider_led',
                        provider_led_training_programme?: true,
                        expression_of_interest: nil)
      end

      it 'returns nil' do
        expect(previous_registration.previous_eoi_lead_provider_name).to be_nil
      end
    end

    context 'when there is no previous training period' do
      it 'returns nil' do
        expect(previous_registration.previous_eoi_lead_provider_name).to be_nil
      end
    end
  end
end
