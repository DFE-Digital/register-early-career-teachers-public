RSpec.describe Schools::RegisterECTWizard::Wizard do
  let(:school) { FactoryBot.create(:school, :state_funded) }
  let(:user) { FactoryBot.create(:user) }
  let(:store) { SessionRepository.new(session: {}, form_key: :register_ect_wizard) }
  let(:wizard) { described_class.new(current_step: :find_ect, author: user, step_params: {}, store:, school:) }

  describe '#allowed_steps' do
    context 'when ECT is already registered' do
      before do
        wizard.ect.update!(ect_at_school_period_id: 123)
      end

      it 'returns only confirmation step' do
        expect(wizard.allowed_steps).to eq([:confirmation])
      end
    end

    context 'when starting the wizard with no data' do
      it 'returns find_ect as the first allowed step' do
        expect(wizard.allowed_steps).to include(:find_ect)
      end

      it 'only allows find_ect step when no TRS data is present' do
        wizard.ect.update!(start_date: '2024-09-01')
        expect(wizard.allowed_steps).to eq([:find_ect])
      end
    end

    context 'when ECT has TRN but is not in TRS' do
      before do
        wizard.ect.update!(trn: '1234567', date_of_birth: '1990-01-01')
        allow(wizard.ect).to receive(:in_trs?).and_return(false)
      end

      it 'includes trn_not_found step' do
        expect(wizard.allowed_steps).to include(:trn_not_found)
      end
    end

    context 'when ECT has TRN and is in TRS but DOB does not match' do
      before do
        wizard.ect.update!(
          trn: '1234567',
          trs_first_name: 'John',
          date_of_birth: '1990-01-01',
          trs_date_of_birth: '1990-01-02'
        )
        allow(wizard.ect).to receive_messages(in_trs?: true, matches_trs_dob?: false)
      end

      it 'includes national_insurance_number step' do
        expect(wizard.allowed_steps).to include(:national_insurance_number)
      end

      context 'and national insurance number is provided but teacher not found' do
        before do
          wizard.ect.update!(national_insurance_number: 'AB123456C')
          # Clear the cached allowed_steps and mock in_trs? to return false after NI number
          wizard.instance_variable_set(:@allowed_steps, nil)
          allow(wizard.ect).to receive(:in_trs?).and_return(false)
        end

        it 'includes not_found step' do
          expect(wizard.allowed_steps).to include(:not_found)
        end
      end
    end

    context 'when ECT is already active at school' do
      before do
        wizard.ect.update!(
          trn: '1234567',
          date_of_birth: '1990-01-01',
          trs_first_name: 'John',
          trs_date_of_birth: '1990-01-01'
        )
        allow(wizard.ect).to receive_messages(in_trs?: true, matches_trs_dob?: true)
        allow(wizard.ect).to receive(:active_at_school?).with(school.urn).and_return(true)
      end

      it 'includes already_active_at_school step' do
        expect(wizard.allowed_steps).to include(:already_active_at_school)
      end
    end

    context 'when ECT has completed induction' do
      before do
        wizard.ect.update!(
          trn: '1234567',
          date_of_birth: '1990-01-01',
          trs_first_name: 'John',
          trs_date_of_birth: '1990-01-01',
          trs_induction_status: 'Passed'
        )
        allow(wizard.ect).to receive_messages(in_trs?: true, matches_trs_dob?: true, active_at_school?: false)
      end

      it 'includes induction_completed step' do
        expect(wizard.allowed_steps).to include(:induction_completed)
      end
    end

    context 'when ECT is exempt from induction' do
      before do
        wizard.ect.update!(
          trn: '1234567',
          date_of_birth: '1990-01-01',
          trs_first_name: 'John',
          trs_date_of_birth: '1990-01-01',
          trs_induction_status: 'Exempt'
        )
        allow(wizard.ect).to receive_messages(in_trs?: true, matches_trs_dob?: true, active_at_school?: false)
      end

      it 'includes induction_exempt step' do
        expect(wizard.allowed_steps).to include(:induction_exempt)
      end
    end

    context 'when ECT has failed induction' do
      before do
        wizard.ect.update!(
          trn: '1234567',
          date_of_birth: '1990-01-01',
          trs_first_name: 'John',
          trs_date_of_birth: '1990-01-01',
          trs_induction_status: 'Failed'
        )
        allow(wizard.ect).to receive_messages(in_trs?: true, matches_trs_dob?: true, active_at_school?: false)
      end

      it 'includes induction_failed step' do
        expect(wizard.allowed_steps).to include(:induction_failed)
      end
    end

    context 'when ECT is prohibited from teaching' do
      before do
        wizard.ect.update!(
          trn: '1234567',
          date_of_birth: '1990-01-01',
          trs_first_name: 'John',
          trs_date_of_birth: '1990-01-01',
          trs_prohibited_from_teaching: true
        )
        allow(wizard.ect).to receive_messages(in_trs?: true, matches_trs_dob?: true, active_at_school?: false)
      end

      it 'includes cannot_register_ect step' do
        expect(wizard.allowed_steps).to include(:cannot_register_ect)
      end
    end

    context 'when progressing through normal flow with TRS data' do
      before do
        wizard.ect.update!(
          trn: '1234567',
          date_of_birth: '1990-01-01',
          trs_first_name: 'John',
          trs_date_of_birth: '1990-01-01',
          change_name: 'no',
          email: 'test@example.com',
          start_date: '2024-09-01',
          working_pattern: 'full_time',
          appropriate_body_id: 1,
          training_programme: 'school_led'
        )
        allow(wizard.ect).to receive_messages(in_trs?: true, matches_trs_dob?: true, active_at_school?: false, email_taken?: false, previously_registered?: false)
      end

      it 'includes all necessary steps for completion' do
        expected_steps = %i[
          find_ect
          review_ect_details
          email_address
          start_date
          working_pattern
          state_school_appropriate_body
          training_programme
          check_answers
        ]

        allowed = wizard.allowed_steps
        expected_steps.each do |step|
          expect(allowed).to include(step), "Expected #{step} to be in allowed steps #{allowed}"
        end
      end

      it 'includes change steps for completed flows' do
        change_steps = %i[
          change_email_address
          change_training_programme
          change_review_ect_details
          change_start_date
          change_working_pattern
        ]

        allowed = wizard.allowed_steps
        change_steps.each do |step|
          expect(allowed).to include(step), "Expected change step #{step} to be in allowed steps"
        end
      end
    end

    context 'when progressing through normal flow after TRS validation' do
      before do
        # Properly set up ECT with TRS data as would happen after find_ect step
        wizard.ect.update!(
          trn: '1234567',
          date_of_birth: '1990-01-01',
          trs_first_name: 'John',
          trs_last_name: 'Doe',
          trs_date_of_birth: '1990-01-01',
          change_name: 'no',
          email: 'test@example.com',
          start_date: '2024-09-01',
          working_pattern: 'full_time',
          appropriate_body_id: 1,
          training_programme: 'school_led'
        )
        allow(wizard.ect).to receive_messages(in_trs?: true, matches_trs_dob?: true, active_at_school?: false, email_taken?: false, previously_registered?: false)
      end

      it 'allows progression through all required steps' do
        expected_steps = %i[
          find_ect
          review_ect_details
          email_address
          start_date
          working_pattern
          state_school_appropriate_body
          training_programme
          check_answers
        ]

        allowed = wizard.allowed_steps
        expected_steps.each do |step|
          expect(allowed).to include(step), "Expected #{step} to be in allowed steps"
        end
      end

      it 'includes review_ect_details and email_address when TRS data is present' do
        allowed = wizard.allowed_steps
        expect(allowed).to include(:review_ect_details)
        expect(allowed).to include(:email_address)
      end
    end

    context 'for independent schools' do
      let(:school) { FactoryBot.create(:school, :independent) }

      before do
        # Set up ECT with TRS data for independent school flow
        wizard.ect.update!(
          trn: '1234567',
          date_of_birth: '1990-01-01',
          trs_first_name: 'John',
          trs_last_name: 'Doe',
          trs_date_of_birth: '1990-01-01',
          change_name: 'no',
          email: 'test@example.com',
          start_date: '2024-09-01',
          working_pattern: 'full_time',
          appropriate_body_id: 1,
          training_programme: 'school_led'
        )
        allow(wizard.ect).to receive_messages(in_trs?: true, matches_trs_dob?: true, active_at_school?: false, email_taken?: false, previously_registered?: false)
      end

      it 'includes independent_school_appropriate_body instead of state_school_appropriate_body' do
        allowed = wizard.allowed_steps
        expect(allowed).to include(:independent_school_appropriate_body)
        expect(allowed).not_to include(:state_school_appropriate_body)
      end
    end

    context 'when the school has previous programme choices' do
      before do
        previous_contract_year = 2023
        current_contract_year  = 2024

        previous_contract_period = FactoryBot.create(:contract_period, year: previous_contract_year)
        current_contract_period  = FactoryBot.create(:contract_period, year: current_contract_year)

        lead_provider = FactoryBot.create(:lead_provider, name: 'Spec Lead Provider')
        delivery_partner = FactoryBot.create(:delivery_partner, name: 'Spec Delivery Partner')

        previous_active_lead_provider = FactoryBot.create(
          :active_lead_provider,
          lead_provider:,
          contract_period: previous_contract_period
        )

        current_active_lead_provider = FactoryBot.create(
          :active_lead_provider,
          lead_provider:,
          contract_period: current_contract_period
        )

        previous_lead_provider_delivery_partnership = FactoryBot.create(
          :lead_provider_delivery_partnership,
          active_lead_provider: previous_active_lead_provider,
          delivery_partner:
        )

        FactoryBot.create(
          :lead_provider_delivery_partnership,
          active_lead_provider: current_active_lead_provider,
          delivery_partner:
        )

        school.update!(
          last_chosen_training_programme: 'provider_led',
          last_chosen_lead_provider: lead_provider
        )

        FactoryBot.create(
          :school_partnership,
          school:,
          lead_provider_delivery_partnership: previous_lead_provider_delivery_partnership
        )

        wizard.ect.update!(
          trn: '1234567',
          date_of_birth: '1990-01-01',
          trs_first_name: 'John',
          trs_last_name: 'Doe',
          trs_date_of_birth: '1990-01-01',
          change_name: 'no',
          email: 'test@example.com',
          start_date: '2024-09-01',
          working_pattern: 'full_time'
        )

        allow(school).to receive(:last_programme_choices?).and_return(true)

        allow(wizard.ect).to receive_messages(
          in_trs?: true,
          matches_trs_dob?: true,
          active_at_school?: false,
          email_taken?: false,
          previously_registered?: false
        )
      end

      it 'includes use_previous_ect_choices step' do
        expect(wizard.allowed_steps).to include(:use_previous_ect_choices)
      end

      context 'and user chooses to use previous choices' do
        before do
          wizard.ect.update!(use_previous_ect_choices: true)
        end

        it 'allows direct progression to check_answers' do
          expect(wizard.allowed_steps).to include(:check_answers)
        end
      end
    end

    context 'when ECT chooses provider-led training' do
      before do
        FactoryBot.create(:contract_period, year: 2024)
        wizard.ect.update!(
          trn: '1234567',
          date_of_birth: '1990-01-01',
          trs_first_name: 'John',
          trs_last_name: 'Doe',
          trs_date_of_birth: '1990-01-01',
          change_name: 'no',
          email: 'test@example.com',
          start_date: '2024-09-01',
          working_pattern: 'full_time',
          appropriate_body_id: 1,
          training_programme: 'provider_led'
        )
        allow(wizard.ect).to receive_messages(in_trs?: true, matches_trs_dob?: true, active_at_school?: false, email_taken?: false, previously_registered?: false, provider_led?: true)
      end

      it 'includes lead_provider step' do
        expect(wizard.allowed_steps).to include(:lead_provider)
      end

      context 'and lead provider is selected' do
        before do
          wizard.ect.update!(lead_provider_id: 1)
        end

        it 'allows progression to check_answers' do
          expect(wizard.allowed_steps).to include(:check_answers)
        end
      end
    end
  end

  describe '#allowed_step?' do
    before do
      allow(wizard).to receive(:allowed_steps).and_return(%i[find_ect review_ect_details])
    end

    it 'returns true for allowed steps' do
      expect(wizard.allowed_step?(:find_ect)).to be true
    end

    it 'returns false for disallowed steps' do
      expect(wizard.allowed_step?(:check_answers)).to be false
    end

    it 'accepts step name parameter' do
      expect(wizard.allowed_step?(:review_ect_details)).to be true
    end

    it 'defaults to current step when no parameter provided' do
      allow(wizard).to receive(:current_step_name).and_return(:find_ect)
      expect(wizard.allowed_step?).to be true
    end
  end

  describe '#allowed_step_path' do
    before do
      allow(wizard).to receive(:allowed_steps).and_return(%i[find_ect review_ect_details])
    end

    it 'returns path for the last allowed step' do
      expect(wizard.allowed_step_path).to include('review-ect-details')
    end
  end

  describe 'change step logic' do
    context 'when ECT has completed the flow' do
      let(:appropriate_body) { FactoryBot.create(:appropriate_body) }

      before do
        wizard.ect.update!(
          trn: '1234567',
          date_of_birth: '1990-01-01',
          trs_first_name: 'John',
          trs_date_of_birth: '1990-01-01',
          change_name: 'no',
          email: 'test@example.com',
          start_date: '2024-09-01',
          working_pattern: 'full_time',
          appropriate_body_id: appropriate_body.id,
          training_programme: 'school_led'
        )
        allow(wizard.ect).to receive_messages(in_trs?: true, matches_trs_dob?: true, active_at_school?: false, email_taken?: false, previously_registered?: false)
      end

      it 'includes change_email_address step' do
        expect(wizard.allowed_steps).to include(:change_email_address)
      end

      it 'includes cant_use_changed_email when email cannot be used' do
        allow(wizard.ect).to receive(:email_taken?).and_return(true)
        expect(wizard.allowed_steps).to include(:cant_use_changed_email)
      end

      context 'for state school' do
        let(:school) { FactoryBot.create(:school, :state_funded) }

        it 'includes change_state_school_appropriate_body step' do
          expect(wizard.allowed_steps).to include(:change_state_school_appropriate_body)
        end

        it 'does not include change_independent_school_appropriate_body step' do
          expect(wizard.allowed_steps).not_to include(:change_independent_school_appropriate_body)
        end
      end

      context 'for independent school' do
        let(:school) { FactoryBot.create(:school, :independent) }

        it 'includes change_independent_school_appropriate_body step' do
          expect(wizard.allowed_steps).to include(:change_independent_school_appropriate_body)
        end

        it 'does not include change_state_school_appropriate_body step' do
          expect(wizard.allowed_steps).not_to include(:change_state_school_appropriate_body)
        end
      end

      it 'includes change_training_programme step' do
        expect(wizard.allowed_steps).to include(:change_training_programme)
      end

      context 'when ECT is not school-led and was previously school-led' do
        before do
          wizard.ect.update!(training_programme: 'provider_led', lead_provider_id: 1)
          allow(wizard.ect).to receive_messages(school_led?: false, was_school_led?: true, provider_led?: true)
        end

        it 'includes training_programme_change_lead_provider step' do
          expect(wizard.allowed_steps).to include(:training_programme_change_lead_provider)
        end
      end

      context 'when ECT is not school-led and was previously school-led (change scenario)' do
        before do
          # Complete the flow with provider-led training and lead provider
          wizard.ect.update!(training_programme: 'provider_led', lead_provider_id: 123)
          # Mock that they were previously school-led to trigger the change step
          allow(wizard.ect).to receive_messages(school_led?: false, was_school_led?: true, provider_led?: true)
        end

        it 'includes training_programme_change_lead_provider step' do
          expect(wizard.allowed_steps).to include(:training_programme_change_lead_provider)
        end
      end

      context 'when ECT is school-led' do
        before do
          allow(wizard.ect).to receive(:school_led?).and_return(true)
        end

        it 'does not include training_programme_change_lead_provider step' do
          expect(wizard.allowed_steps).not_to include(:training_programme_change_lead_provider)
        end
      end
    end
  end

  describe 'always allowed steps integration' do
    it 'does not allow change steps when user has not reached check_answers' do
      # Change steps should only be allowed through normal wizard progression
      expect(wizard.allowed_step?('change_email_address')).to be false
      expect(wizard.allowed_step?('change_training_programme')).to be false
    end

    it 'does not allow no_previous_ect_choices_change steps when user has not reached check_answers' do
      expect(wizard.allowed_step?('no_previous_ect_choices_change_training_programme')).to be false
    end

    it 'does not allow training_programme_change steps when user has not reached check_answers' do
      expect(wizard.allowed_step?('training_programme_change_lead_provider')).to be false
    end

    it 'does not allow error steps when error conditions are not met' do
      # Error steps should only be allowed when the actual error conditions are met
      expect(wizard.allowed_step?('not_found')).to be false
      expect(wizard.allowed_step?('cant_use_email')).to be false
      expect(wizard.allowed_step?('cant_use_changed_email')).to be false
      expect(wizard.allowed_step?('induction_completed')).to be false
    end

    it 'does not allow regular steps when not in allowed_steps' do
      # These should only be allowed if they're in the calculated allowed_steps
      allow(wizard).to receive(:allowed_steps).and_return([:find_ect])
      expect(wizard.allowed_step?('email_address')).to be false
      expect(wizard.allowed_step?('check_answers')).to be false
    end
  end

  describe 'contract period validation' do
    before do
      wizard.ect.update!(
        trn: '1234567',
        date_of_birth: '1990-01-01',
        trs_first_name: 'John',
        trs_date_of_birth: '1990-01-01',
        change_name: 'no',
        email: 'test@example.com',
        start_date: future_date.strftime('%Y-%m-%d')
      )
      allow(wizard.ect).to receive_messages(in_trs?: true, matches_trs_dob?: true, active_at_school?: false, email_taken?: false, previously_registered?: false)
    end

    let(:future_date) { 1.month.from_now }

    context 'when start date is in future and contract period is not enabled' do
      before do
        allow(wizard).to receive_messages(past_start_date?: false, start_date_contract_period: double(enabled?: false))
      end

      it 'includes cannot_register_ect_yet step' do
        expect(wizard.allowed_steps).to include(:cannot_register_ect_yet)
      end

      it 'does not include working_pattern step' do
        expect(wizard.allowed_steps).not_to include(:working_pattern)
      end
    end

    context 'when start date is in past' do
      before do
        allow(wizard).to receive(:past_start_date?).and_return(true)
      end

      it 'includes working_pattern step' do
        expect(wizard.allowed_steps).to include(:working_pattern)
      end

      it 'does not include cannot_register_ect_yet step' do
        expect(wizard.allowed_steps).not_to include(:cannot_register_ect_yet)
      end
    end

    context 'when start date is in future but contract period is enabled' do
      before do
        allow(wizard).to receive_messages(past_start_date?: false, start_date_contract_period: double(enabled?: true))
      end

      it 'includes working_pattern step' do
        expect(wizard.allowed_steps).to include(:working_pattern)
      end

      it 'does not include cannot_register_ect_yet step' do
        expect(wizard.allowed_steps).not_to include(:cannot_register_ect_yet)
      end
    end
  end
end
