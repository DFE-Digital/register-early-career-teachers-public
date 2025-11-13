RSpec.describe Schools::RegisterMentorWizard::RegistrationSession::Status do
  subject(:status) { described_class.new(registration_session:, queries:) }

  let(:email) { 'mentor@example.com' }
  let(:trn) { '7654321' }
  let(:corrected_name) { nil }
  let(:trs_first_name) { nil }
  let(:date_of_birth) { nil }
  let(:trs_date_of_birth) { nil }
  let(:trs_prohibited_from_teaching) { false }
  let(:store) { {} }
  let(:ect_lead_provider) { nil }

  let(:registration_session) do
    Struct.new(
      :email,
      :trn,
      :corrected_name,
      :trs_first_name,
      :date_of_birth,
      :trs_date_of_birth,
      :trs_prohibited_from_teaching,
      :store,
      :ect_lead_provider
    ).new(
      email,
      trn,
      corrected_name,
      trs_first_name,
      date_of_birth,
      trs_date_of_birth,
      trs_prohibited_from_teaching,
      store,
      ect_lead_provider
    )
  end

  let(:mentor_periods_relation) { MentorAtSchoolPeriod.none }
  let(:previous_school_periods_relation) { MentorAtSchoolPeriod.none }
  let(:contract_period) { nil }
  let(:ect) { nil }
  let(:queries) do
    instance_double(Schools::RegisterMentorWizard::RegistrationSession::Queries,
                    mentor_at_school_periods: mentor_periods_relation,
                    previous_school_mentor_at_school_periods: previous_school_periods_relation,
                    contract_period:,
                    ect:)
  end

  describe '#email_taken?' do
    let(:teacher_email_service) { instance_double(Schools::TeacherEmail, is_currently_used?: in_use) }

    before do
      allow(Schools::TeacherEmail).to receive(:new).with(email:, trn:).and_return(teacher_email_service)
    end

    context 'when the email is already in use' do
      let(:in_use) { true }

      it 'returns true' do
        expect(status.email_taken?).to be(true)
      end
    end

    context 'when the email is available' do
      let(:in_use) { false }

      it 'returns false' do
        expect(status.email_taken?).to be(false)
      end
    end
  end

  describe '#corrected_name?' do
    context 'when a corrected name is present' do
      let(:corrected_name) { 'New Name' }

      it 'returns true' do
        expect(status.corrected_name?).to be(true)
      end
    end

    context 'when no corrected name is provided' do
      it 'returns false' do
        expect(status.corrected_name?).to be(false)
      end
    end
  end

  describe '#in_trs?' do
    context 'when the TRS record contains a first name' do
      let(:trs_first_name) { 'Lisa' }

      it 'returns true' do
        expect(status.in_trs?).to be(true)
      end
    end

    context 'when the TRS record is blank' do
      it 'returns false' do
        expect(status.in_trs?).to be(false)
      end
    end
  end

  describe '#matches_trs_dob?' do
    context 'when both dates are present and match' do
      let(:date_of_birth) { Date.new(1980, 1, 1) }
      let(:trs_date_of_birth) { Date.new(1980, 1, 1) }

      it 'returns true' do
        expect(status.matches_trs_dob?).to be(true)
      end
    end

    context 'when either date is missing' do
      let(:date_of_birth) { nil }
      let(:trs_date_of_birth) { Date.new(1980, 1, 1) }

      it 'returns false' do
        expect(status.matches_trs_dob?).to be(false)
      end
    end

    context 'when the dates do not match' do
      let(:date_of_birth) { Date.new(1980, 1, 1) }
      let(:trs_date_of_birth) { Date.new(1981, 1, 1) }

      it 'returns false' do
        expect(status.matches_trs_dob?).to be(false)
      end
    end
  end

  describe '#funding_available?' do
    let(:eligibility_service) { instance_double(Teachers::MentorFundingEligibility, eligible?: eligible) }
    let(:eligible) { true }

    before do
      allow(Teachers::MentorFundingEligibility).to receive(:new).with(trn:).and_return(eligibility_service)
    end

    it 'delegates to the mentor funding eligibility service' do
      expect(status.funding_available?).to be(true)
    end

    context 'when the mentor is not eligible' do
      let(:eligible) { false }

      it 'returns false' do
        expect(status.funding_available?).to be(false)
      end
    end
  end

  describe '#eligible_for_funding?' do
    let(:eligibility_service) { instance_double(Teachers::MentorFundingEligibility, eligible?: eligible) }
    let(:eligible) { true }

    before do
      allow(Teachers::MentorFundingEligibility).to receive(:new).with(trn:).and_return(eligibility_service)
    end

    it 'mirrors the funding_available? result' do
      expect(status.eligible_for_funding?).to be(true)
    end
  end

  describe '#became_ineligible_for_funding?' do
    let(:eligibility_service) { instance_double(Teachers::MentorFundingEligibility, ineligible?: true) }

    before do
      allow(Teachers::MentorFundingEligibility).to receive(:new).with(trn:).and_return(eligibility_service)
    end

    it 'returns the service ineligible? response' do
      expect(status.became_ineligible_for_funding?).to be(true)
    end
  end

  describe '#prohibited_from_teaching?' do
    context 'when TRS states the mentor is prohibited' do
      let(:trs_prohibited_from_teaching) { true }

      it 'returns true' do
        expect(status.prohibited_from_teaching?).to be(true)
      end
    end

    context 'when the mentor is allowed to teach' do
      it 'returns false' do
        expect(status.prohibited_from_teaching?).to be(false)
      end
    end
  end

  describe '#previously_registered_as_mentor?' do
    context 'when mentor at school periods exist' do
      let(:mentor_periods_relation) { MentorAtSchoolPeriod.where(id: FactoryBot.create(:mentor_at_school_period).id) }

      it 'returns true' do
        expect(status.previously_registered_as_mentor?).to be(true)
      end
    end

    context 'when there are no mentor at school periods' do
      it 'returns false' do
        expect(status.previously_registered_as_mentor?).to be(false)
      end
    end
  end

  describe '#currently_mentor_at_another_school?' do
    context 'when there is an ongoing periods at another school' do
      let(:previous_school_periods_relation) { MentorAtSchoolPeriod.where(id: FactoryBot.create(:mentor_at_school_period, :ongoing).id) }

      it 'returns true' do
        expect(status.currently_mentor_at_another_school?).to be(true)
      end
    end

    context 'when there are no periods at another school' do
      it 'returns false' do
        expect(status.currently_mentor_at_another_school?).to be(false)
      end
    end
  end

  describe '#previous_school_closed_mentor_at_school_periods?' do
    context 'when a previous school period has a finished_on date' do
      let(:previous_school_periods_relation) { MentorAtSchoolPeriod.where(id: FactoryBot.create(:mentor_at_school_period, finished_on: 1.week.ago).id) }

      it 'returns true' do
        expect(status.previous_school_closed_mentor_at_school_periods?).to be(true)
      end
    end

    context 'when no previous school periods have finished' do
      it 'returns false' do
        expect(status.previous_school_closed_mentor_at_school_periods?).to be(false)
      end
    end
  end

  describe '#mentorship_status' do
    context 'when there is an ongoing mentor period' do
      let(:mentor_periods_relation) { MentorAtSchoolPeriod.where(id: FactoryBot.create(:mentor_at_school_period, :ongoing).id) }

      it 'returns :currently_a_mentor' do
        expect(status.mentorship_status).to eq(:currently_a_mentor)
      end
    end

    context 'when there are only closed periods' do
      let(:mentor_periods_relation) { MentorAtSchoolPeriod.where(id: FactoryBot.create(:mentor_at_school_period, finished_on: 1.day.ago).id) }

      it 'returns :previously_a_mentor' do
        expect(status.mentorship_status).to eq(:previously_a_mentor)
      end
    end

    context 'when there are no mentor periods' do
      it 'raises an error' do
        expect { status.mentorship_status }
          .to raise_error(described_class::MentorStatusError, /No mentor_at_school_periods/)
      end
    end
  end

  describe '#provider_led_ect?' do
    let(:ect) { instance_double(ECTAtSchoolPeriod, provider_led_training_programme?: true) }

    it 'delegates to the ect instance' do
      expect(status.provider_led_ect?).to be(true)
    end
  end

  describe '#ect_lead_provider_invalid?' do
    context 'when no ect lead provider is stored' do
      it 'returns false' do
        expect(status.ect_lead_provider_invalid?).to be(false)
      end
    end

    context 'when a provider is present' do
      let(:ect_lead_provider) { FactoryBot.create(:lead_provider) }
      let(:contract_period) { instance_double(ContractPeriod) }
      let(:active_service) { instance_double(LeadProviders::Active, active_in_contract_period?: active) }

      before do
        allow(LeadProviders::Active).to receive(:new).with(ect_lead_provider).and_return(active_service)
      end

      context 'when the provider is active for the contract period' do
        let(:active) { true }

        it 'returns false' do
          expect(status.ect_lead_provider_invalid?).to be(false)
        end
      end

      context 'when the provider is not active' do
        let(:active) { false }

        it 'returns true' do
          expect(status.ect_lead_provider_invalid?).to be(true)
        end
      end
    end
  end

  describe '#mentoring_at_new_school_only?' do
    context 'when the store has no explicit value' do
      it 'defaults to true' do
        expect(status.mentoring_at_new_school_only?).to be(true)
      end
    end

    context 'when the store records a no answer' do
      let(:store) { { "mentoring_at_new_school_only" => "no" } }

      it 'returns false' do
        expect(status.mentoring_at_new_school_only?).to be(false)
      end
    end
  end
end
