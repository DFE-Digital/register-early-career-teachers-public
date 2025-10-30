RSpec.describe Schools::RegisterECTWizard::Context::Status do
  subject(:status) { described_class.new(context:, queries:) }

  let(:email) { 'ect@example.com' }
  let(:trn) { '1234567' }
  let(:trs_first_name) { nil }
  let(:trs_induction_status) { nil }
  let(:trs_prohibited_from_teaching) { false }
  let(:ect_at_school_period_id) { nil }
  let(:previous_training_programme) { nil }
  let(:training_programme) { nil }
  let(:date_of_birth) { nil }
  let(:trs_date_of_birth) { nil }

  let(:context) do
    Struct.new(
      :email,
      :trn,
      :trs_first_name,
      :trs_induction_status,
      :trs_prohibited_from_teaching,
      :ect_at_school_period_id,
      :previous_training_programme,
      :training_programme,
      :date_of_birth,
      :trs_date_of_birth
    ).new(
      email,
      trn,
      trs_first_name,
      trs_induction_status,
      trs_prohibited_from_teaching,
      ect_at_school_period_id,
      previous_training_programme,
      training_programme,
      date_of_birth,
      trs_date_of_birth
    )
  end

  let(:previous_training_period) { nil }
  let(:queries) do
    instance_double(Schools::RegisterECTWizard::Context::Queries, previous_training_period:)
  end

  describe '#cant_use_email?' do
    let(:teacher_email_service) { instance_double(Schools::TeacherEmail, is_currently_used?: result) }

    before do
      allow(Schools::TeacherEmail).to receive(:new).with(email:, trn:).and_return(teacher_email_service)
    end

    context 'when the email is already in use' do
      let(:result) { true }

      it 'returns true' do
        expect(status.cant_use_email?).to be(true)
      end
    end

    context 'when the email is available' do
      let(:result) { false }

      it 'returns false' do
        expect(status.cant_use_email?).to be(false)
      end
    end
  end

  describe '#in_trs?' do
    context 'when TRS first name is present' do
      let(:trs_first_name) { 'Lisa' }

      it 'returns true' do
        expect(status.in_trs?).to be(true)
      end
    end

    context 'when TRS first name is blank' do
      let(:trs_first_name) { nil }

      it 'returns false' do
        expect(status.in_trs?).to be(false)
      end
    end
  end

  describe '#induction_completed?' do
    context "when TRS induction status is 'Passed'" do
      let(:trs_induction_status) { 'Passed' }

      it 'returns true' do
        expect(status.induction_completed?).to be(true)
      end
    end

    context 'when TRS induction status is different' do
      let(:trs_induction_status) { 'Failed' }

      it 'returns false' do
        expect(status.induction_completed?).to be(false)
      end
    end
  end

  describe '#induction_exempt?' do
    let(:trs_induction_status) { 'Exempt' }

    it 'returns true when exempt' do
      expect(status.induction_exempt?).to be(true)
    end

    context 'when not exempt' do
      let(:trs_induction_status) { 'Passed' }

      it 'returns false' do
        expect(status.induction_exempt?).to be(false)
      end
    end
  end

  describe '#induction_failed?' do
    let(:trs_induction_status) { 'Failed' }

    it 'returns true when failed' do
      expect(status.induction_failed?).to be(true)
    end

    context 'when induction has not failed' do
      let(:trs_induction_status) { 'Passed' }

      it 'returns false' do
        expect(status.induction_failed?).to be(false)
      end
    end
  end

  describe '#prohibited_from_teaching?' do
    context 'when the teacher is prohibited' do
      let(:trs_prohibited_from_teaching) { true }

      it 'returns true' do
        expect(status.prohibited_from_teaching?).to be(true)
      end
    end

    context 'when the teacher is not prohibited' do
      let(:trs_prohibited_from_teaching) { false }

      it 'returns false' do
        expect(status.prohibited_from_teaching?).to be(false)
      end
    end
  end

  describe '#registered?' do
    context 'when an ECT at school period id is stored' do
      let(:ect_at_school_period_id) { 123 }

      it 'returns true' do
        expect(status.registered?).to be(true)
      end
    end

    context 'when the ECT has not been registered' do
      let(:ect_at_school_period_id) { nil }

      it 'returns false' do
        expect(status.registered?).to be(false)
      end
    end
  end

  describe '#was_school_led?' do
    context "when the previous training programme was 'school_led'" do
      let(:previous_training_programme) { 'school_led' }

      it 'returns true' do
        expect(status.was_school_led?).to be(true)
      end
    end

    context 'when the previous training programme was different' do
      let(:previous_training_programme) { 'provider_led' }

      it 'returns false' do
        expect(status.was_school_led?).to be(false)
      end
    end
  end

  describe '#matches_trs_dob?' do
    context 'when both dates of birth are present and match' do
      let(:date_of_birth) { Date.new(1985, 3, 4) }
      let(:trs_date_of_birth) { Date.new(1985, 3, 4) }

      it 'returns true' do
        expect(status.matches_trs_dob?).to be(true)
      end
    end

    context 'when the TRS date of birth differs' do
      let(:date_of_birth) { Date.new(1985, 3, 4) }
      let(:trs_date_of_birth) { Date.new(1986, 1, 1) }

      it 'returns false' do
        expect(status.matches_trs_dob?).to be(false)
      end
    end

    context 'when either date is missing' do
      let(:date_of_birth) { nil }
      let(:trs_date_of_birth) { Date.new(1985, 3, 4) }

      it 'returns false' do
        expect(status.matches_trs_dob?).to be(false)
      end
    end
  end

  describe '#previous_provider_led?' do
    context 'when there is no previous training period' do
      let(:previous_training_period) { nil }

      it 'returns nil' do
        expect(status.previous_provider_led?).to be_nil
      end
    end

    context 'when there is a previous training period' do
      let(:previous_training_period) do
        instance_double(TrainingPeriod, provider_led_training_programme?: provider_led_training_programme)
      end

      context 'and it was provider led' do
        let(:provider_led_training_programme) { true }

        it 'returns true' do
          expect(status.previous_provider_led?).to be(true)
        end
      end

      context 'and it was not provider led' do
        let(:provider_led_training_programme) { false }

        it 'returns false' do
          expect(status.previous_provider_led?).to be(false)
        end
      end
    end
  end

  describe '#provider_led?' do
    context "when the training programme is 'provider_led'" do
      let(:training_programme) { 'provider_led' }

      it 'returns true' do
        expect(status.provider_led?).to be(true)
      end
    end

    context 'when the training programme is different' do
      let(:training_programme) { 'school_led' }

      it 'returns false' do
        expect(status.provider_led?).to be(false)
      end
    end
  end

  describe '#school_led?' do
    context "when the training programme is 'school_led'" do
      let(:training_programme) { 'school_led' }

      it 'returns true' do
        expect(status.school_led?).to be(true)
      end
    end

    context 'when the training programme is different' do
      let(:training_programme) { 'provider_led' }

      it 'returns false' do
        expect(status.school_led?).to be(false)
      end
    end
  end
end
