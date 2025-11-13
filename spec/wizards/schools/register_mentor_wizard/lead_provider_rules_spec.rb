RSpec.describe Schools::RegisterMentorWizard::LeadProviderRules do
  subject(:rules) { described_class.new(registration_session) }

  let(:registration_session) { instance_double(Schools::RegisterMentorWizard::RegistrationSession) }

  describe '#show_row_in_check_your_answers?' do
    it 'returns true when provider-led, mentoring at new school only and funding available' do
      allow(registration_session).to receive_messages(
        provider_led_ect?: true,
        mentoring_at_new_school_only?: true,
        funding_available?: true,
        ect_lead_provider_invalid?: false
      )
      expect(rules.show_row_in_check_your_answers?).to be true
    end

    it 'returns true when ect lead provider is invalid' do
      allow(registration_session).to receive_messages(
        provider_led_ect?: true,
        mentoring_at_new_school_only?: false,
        funding_available?: false,
        ect_lead_provider_invalid?: true
      )
      expect(rules.show_row_in_check_your_answers?).to be true
    end

    it 'returns false when not provider-led, mentoring at new school only, funding not available and ect lead provider valid' do
      allow(registration_session).to receive_messages(
        provider_led_ect?: false,
        mentoring_at_new_school_only?: false,
        funding_available?: false,
        ect_lead_provider_invalid?: false
      )
      expect(rules.show_row_in_check_your_answers?).to be false
    end
  end

  describe '#needs_selection_for_new_registration?' do
    it 'returns true when mentor not registered and ect lead provider invalid' do
      allow(registration_session).to receive_messages(
        previously_registered_as_mentor?: false,
        ect_lead_provider_invalid?: true
      )
      expect(rules.needs_selection_for_new_registration?).to be true
    end

    it 'returns false when mentor registered and ect lead provider valid' do
      allow(registration_session).to receive_messages(
        previously_registered_as_mentor?: true,
        ect_lead_provider_invalid?: false
      )
      expect(rules.needs_selection_for_new_registration?).to be false
    end
  end

  describe '#previous_step_from_lead_provider' do
    context 'when ect lead provider invalid and mentor not previously registered' do
      it 'returns :email_address' do
        allow(registration_session).to receive_messages(
          ect_lead_provider_invalid?: true,
          previously_registered_as_mentor?: false
        )
        expect(rules.previous_step_from_lead_provider).to eq(:email_address)
      end
    end

    context 'when ect lead provider invalid and mentor previously registered' do
      it 'returns :previous_training_period_details' do
        allow(registration_session).to receive_messages(
          ect_lead_provider_invalid?: true,
          previously_registered_as_mentor?: true
        )
        expect(rules.previous_step_from_lead_provider).to eq(:previous_training_period_details)
      end
    end

    context 'when ect lead provider valid and mentor not registered' do
      it 'returns :programme_choices' do
        allow(registration_session).to receive_messages(
          ect_lead_provider_invalid?: false,
          previously_registered_as_mentor?: false
        )
        expect(rules.previous_step_from_lead_provider).to eq(:programme_choices)
      end
    end
  end
end
