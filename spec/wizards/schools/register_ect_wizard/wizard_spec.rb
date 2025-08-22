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

      it 'allows progression through later steps when TRS data is not present' do
        # Should allow start_date, working_pattern, etc. when no TRS data
        wizard.ect.update!(start_date: '2024-09-01')
        expect(wizard.allowed_steps).to include(:start_date, :working_pattern)
      end
    end

    context 'when ECT has TRN but is not in TRS' do
      before do
        wizard.ect.update!(trn: '1234567')
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
          # Need to allow the initial in_trs? check to pass, then fail after NI number
          call_count = 0
          allow(wizard.ect).to receive(:in_trs?) do
            call_count += 1
            call_count == 1 # First call passes, subsequent calls fail
          end
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
          trs_first_name: 'John',
          trs_date_of_birth: '1990-01-01',
          prohibited_from_teaching: true
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
          trs_first_name: 'John',
          trs_date_of_birth: '1990-01-01',
          change_name: 'no',
          email: 'test@example.com',
          start_date: '2024-09-01',
          working_pattern: 'full_time',
          appropriate_body_id: 1,
          training_programme: 'school_led'
        )
        allow(wizard.ect).to receive_messages(in_trs?: true, matches_trs_dob?: true, active_at_school?: false, cant_use_email?: false, previously_registered?: false)
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

    context 'when progressing through flow without TRS data (test scenario)' do
      before do
        # Simulate a test scenario where we skip find_ect and go straight to later steps
        wizard.ect.update!(
          start_date: '2024-09-01',
          working_pattern: 'full_time',
          appropriate_body_id: 1,
          training_programme: 'school_led'
        )
      end

      it 'allows progression without requiring TRS validation steps' do
        expected_steps = %i[
          find_ect
          start_date
          working_pattern
          state_school_appropriate_body
          training_programme
          check_answers
        ]

        allowed = wizard.allowed_steps
        expected_steps.each do |step|
          expect(allowed).to include(step), "Expected #{step} to be in allowed steps for test scenario"
        end
      end

      it 'does not require review_ect_details or email_address when no TRS data' do
        allowed = wizard.allowed_steps
        expect(allowed).not_to include(:review_ect_details)
        expect(allowed).not_to include(:email_address)
      end
    end

    context 'for independent schools' do
      let(:school) { FactoryBot.create(:school, :independent) }

      before do
        wizard.ect.update!(
          start_date: '2024-09-01',
          working_pattern: 'full_time',
          appropriate_body_id: 1,
          training_programme: 'school_led'
        )
      end

      it 'includes independent_school_appropriate_body instead of state_school_appropriate_body' do
        allowed = wizard.allowed_steps
        expect(allowed).to include(:independent_school_appropriate_body)
        expect(allowed).not_to include(:state_school_appropriate_body)
      end
    end

    context 'when school has previous programme choices' do
      before do
        allow(school).to receive(:last_programme_choices?).and_return(true)
        wizard.ect.update!(
          start_date: '2024-09-01',
          working_pattern: 'full_time'
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
        wizard.ect.update!(
          start_date: '2024-09-01',
          working_pattern: 'full_time',
          appropriate_body_id: 1,
          training_programme: 'provider_led'
        )
        allow(wizard.ect).to receive(:provider_led?).and_return(true)
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
end
