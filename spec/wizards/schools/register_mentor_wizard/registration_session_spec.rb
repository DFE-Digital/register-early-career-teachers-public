describe Schools::RegisterMentorWizard::RegistrationSession do
  subject(:registration_session) { described_class.new(store) }

  let(:school) { FactoryBot.create(:school) }
  let(:author) { FactoryBot.create(:school_user, school_urn: school.urn) }
  let(:store) do
    FactoryBot.build(:session_repository,
                     trn: '3002586',
                     date_of_birth: '11-10-1945',
                     trs_first_name: 'Dusty',
                     trs_last_name: 'Rhodes',
                     trs_date_of_birth: '1945-10-11',
                     corrected_name: nil,
                     email: 'dusty@rhodes.com',
                     school_urn: school.urn)
  end

  describe '#active_at_school?' do
    let(:teacher) { FactoryBot.create(:teacher, trn: '3002586') }

    context 'when the mentor has an ongoing mentor record at the school' do
      let!(:ongoing_mentor_record) { FactoryBot.create(:mentor_at_school_period, :ongoing, school:, teacher:) }

      it 'returns true' do
        expect(registration_session.active_at_school?).to be(true)
      end
    end

    context 'when the mentor has no ongoing mentor record at the school' do
      let!(:ongoing_mentor_record) { FactoryBot.create(:mentor_at_school_period, school:, teacher:) }

      it 'returns false' do
        expect(registration_session.active_at_school?).to be(false)
      end
    end
  end

  describe '#active_record_at_school' do
    let(:teacher) { FactoryBot.create(:teacher, trn: '3002586') }

    context 'when the mentor has an ongoing mentor record at the school' do
      let!(:ongoing_mentor_record) { FactoryBot.create(:mentor_at_school_period, :ongoing, school:, teacher:) }

      it 'returns the mentor record' do
        expect(registration_session.active_record_at_school).to eq(ongoing_mentor_record)
      end
    end

    context 'when the mentor has no ongoing mentor record at the school' do
      let!(:existing_mentor_record) { FactoryBot.create(:mentor_at_school_period, school:, teacher:) }

      it 'returns nil' do
        expect(registration_session.active_record_at_school).to be_nil
      end
    end
  end

  describe '#email_taken?' do
    let(:teacher_email_service) { instance_double(Schools::TeacherEmail) }

    before do
      allow(Schools::TeacherEmail).to receive(:new).with(email: registration_session.email, trn: registration_session.trn).and_return(teacher_email_service)
    end

    context "when the email is used in an ongoing school period" do
      before { allow(teacher_email_service).to receive(:is_currently_used?).and_return(true) }

      it "returns true" do
        expect(subject.email_taken?).to be true
      end
    end

    context "when the email is not used in an ongoing school period" do
      before { allow(teacher_email_service).to receive(:is_currently_used?).and_return(false) }

      it "returns false" do
        expect(subject.email_taken?).to be false
      end
    end
  end

  describe '#email' do
    it 'returns the email address' do
      expect(registration_session.email).to eq("dusty@rhodes.com")
    end
  end

  describe '#full_name' do
    context 'when corrected_name is not set' do
      it 'returns the full name by joining first and last names of the mentor' do
        expect(registration_session.full_name).to eq("Dusty Rhodes")
      end
    end

    context 'when corrected_name is set' do
      before do
        store.corrected_name = 'Randy Marsh'
      end

      it 'returns the corrected_name as the full name' do
        expect(registration_session.full_name).to eq('Randy Marsh')
      end
    end
  end

  describe '#formatted_date_of_birth' do
    it 'formats the date of birth in the govuk format' do
      expect(registration_session.formatted_date_of_birth).to eq("11 October 1945")
    end
  end

  describe '#in_trs?' do
    context "when trs_first_name has been set" do
      it 'returns true' do
        expect(registration_session).to be_in_trs
      end
    end

    context "when trs_first_name has not been set or is blank" do
      before do
        store.trs_first_name = nil
      end

      it 'returns false' do
        expect(registration_session).not_to be_in_trs
      end
    end
  end

  describe '#matches_trs_dob?' do
    context "when date_of_birth is blank" do
      before do
        store.date_of_birth = nil
      end

      it 'returns false' do
        expect(registration_session).not_to be_matches_trs_dob
      end
    end

    context "when trs_date_of_birth is blank" do
      before do
        store.trs_date_of_birth = nil
      end

      it 'returns false' do
        expect(registration_session).not_to be_matches_trs_dob
      end
    end

    context "when date_of_birth and trs_date_of_birth are different dates" do
      before do
        store.date_of_birth = "1935-10-11"
      end

      it 'returns false' do
        expect(registration_session).not_to be_matches_trs_dob
      end
    end

    context "when date_of_birth and trs_date_of_birth are the same date" do
      it 'returns true' do
        expect(registration_session).to be_matches_trs_dob
      end
    end
  end

  describe '#previous_training_period' do
    let(:teacher) { FactoryBot.create(:teacher, trn: registration_session.trn) }
    let!(:training_period) { FactoryBot.create(:training_period, :for_mentor, mentor_at_school_period:, started_on: Date.new(2025, 3, 1)) }
    let!(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, :ongoing, teacher:, started_on: Date.new(2025, 1, 1)) }

    it 'returns the latest training period for the mentor' do
      expect(registration_session.previous_training_period).to eq(training_period)
    end
  end

  describe '#register!' do
    let(:teacher) { Teacher.first }
    let(:mentor_at_school_period) { teacher.mentor_at_school_periods.first }

    it "creates a new teacher registered at the given school" do
      expect(Teacher.find_by_trn(registration_session.trn)).to be_nil

      registration_session.register!(author:)

      expect(teacher.trn).to eq(registration_session.trn)
      expect(mentor_at_school_period.school_id).to eq(school.id)
      expect(mentor_at_school_period.started_on).to eq(Date.current)
      expect(mentor_at_school_period.email).to eq('dusty@rhodes.com')
    end
  end

  describe '#school' do
    context 'when school_urn is set' do
      it 'returns the school instance' do
        expect(registration_session.school).to eql(school)
      end
    end

    context 'when school_urn is not set' do
      before do
        registration_session.update!(school_urn: nil)
      end

      it 'returns nil' do
        expect(registration_session.school).to be_nil
      end
    end
  end

  describe '#trn' do
    it 'returns the trn' do
      expect(registration_session.trn).to eq("3002586")
    end
  end

  describe '#finish_existing_at_school_periods' do
    context "when mentoring_at_new_school_only set to yes" do
      before { store.mentoring_at_new_school_only = "yes" }

      it { expect(registration_session.finish_existing_at_school_periods).to be(true) }
    end

    context "when mentoring_at_new_school_only set to no" do
      before { store.mentoring_at_new_school_only = "no" }

      it { expect(registration_session.finish_existing_at_school_periods).to be(false) }
    end
  end

  describe '#lead_providers_within_contract_period' do
    let!(:contract_period) { FactoryBot.create(:contract_period, started_on: Date.new(2025, 1, 1), finished_on: Date.new(2025, 12, 31)) }
    let!(:lp_in) { FactoryBot.create(:lead_provider) }
    let!(:lp_out) { FactoryBot.create(:lead_provider) }

    before do
      FactoryBot.create(:active_lead_provider, contract_period:, lead_provider: lp_in)
      store.started_on = "2025-05-01"
    end

    it 'returns lead providers active in the contract period' do
      expect(registration_session.lead_providers_within_contract_period).to include(lp_in)
      expect(registration_session.lead_providers_within_contract_period).not_to include(lp_out)
    end

    context 'when no contract period matches the started_on' do
      before { store.started_on = nil }

      it 'falls back to today and returns providers in the current contract period' do
        travel_to(Date.new(2025, 5, 1)) do
          expect(registration_session.lead_providers_within_contract_period).to include(lp_in)
          expect(registration_session.lead_providers_within_contract_period).not_to include(lp_out)
        end
      end
    end

    context 'when today is outside any contract period' do
      before { store.started_on = nil }

      it 'returns an empty array' do
        travel_to(Date.new(2024, 6, 1)) do
          expect(registration_session.lead_providers_within_contract_period).to eq([])
        end
      end
    end
  end

  describe '#mentoring_at_new_school_only?' do
    context 'when mentoring_at_new_school_only is not set' do
      it 'returns true by default' do
        expect(registration_session.mentoring_at_new_school_only?).to be true
      end
    end

    context 'when mentoring_at_new_school_only is yes' do
      before { store.mentoring_at_new_school_only = 'yes' }

      it 'returns true' do
        expect(registration_session.mentoring_at_new_school_only?).to be true
      end
    end

    context 'when mentoring_at_new_school_only is no' do
      before { store.mentoring_at_new_school_only = 'no' }

      it 'returns false' do
        expect(registration_session.mentoring_at_new_school_only?).to be false
      end
    end
  end

  describe '#mentorship_status' do
    let(:teacher) { FactoryBot.create(:teacher, trn: registration_session.trn) }

    context 'when there is an ongoing mentor_at_school_period' do
      let!(:ongoing_period) { FactoryBot.create(:mentor_at_school_period, :ongoing, school:, teacher:) }

      it 'returns :currently_a_mentor' do
        expect(registration_session.mentorship_status).to eq(:currently_a_mentor)
      end
    end

    context 'when there are past mentor_at_school_periods but none ongoing' do
      let!(:closed_period) { FactoryBot.create(:mentor_at_school_period, school:, teacher:, started_on: 3.years.ago) }

      it 'returns :previously_a_mentor' do
        expect(registration_session.mentorship_status).to eq(:previously_a_mentor)
      end
    end

    context 'when there are past mentor_at_school_periods and some ongoing' do
      let!(:closed_period) { FactoryBot.create(:mentor_at_school_period, school:, teacher:, started_on: 3.years.ago) }
      let!(:ongoing_period) { FactoryBot.create(:mentor_at_school_period, :ongoing, school:, teacher:) }

      it 'returns :currently_a_mentor' do
        expect(registration_session.mentorship_status).to eq(:currently_a_mentor)
      end
    end

    context 'when there are no mentor_at_school_periods' do
      it 'raises an error' do
        expect { registration_session.mentorship_status }
          .to raise_error(described_class::Status::MentorStatusError, /No mentor_at_school_periods/)
      end
    end
  end

  describe '#currently_mentor_at_another_school?' do
    let(:teacher) { FactoryBot.create(:teacher, trn: registration_session.trn) }
    let(:other_school) { FactoryBot.create(:school) }

    before { store.start_date = Date.current }

    context 'when there is an ongoing record at another school' do
      before do
        FactoryBot.create(:mentor_at_school_period, :ongoing, school: other_school, teacher:)
      end

      it 'returns true' do
        expect(registration_session.currently_mentor_at_another_school?).to be(true)
      end
    end

    context 'when there are no qualifying records' do
      it 'returns false' do
        expect(registration_session.currently_mentor_at_another_school?).to be(false)
      end
    end
  end

  describe '#previous_school_closed_mentor_at_school_periods?' do
    let(:teacher) { FactoryBot.create(:teacher, trn: registration_session.trn) }
    let(:other_school) { FactoryBot.create(:school) }

    before { store.start_date = Date.current - 1.year }

    context 'when a previous school period finished recently' do
      before do
        FactoryBot.create(:mentor_at_school_period,
                          school: other_school,
                          teacher:,
                          started_on: 2.years.ago,
                          finished_on: 1.month.ago)
      end

      it 'returns true' do
        expect(registration_session.previous_school_closed_mentor_at_school_periods?).to be(true)
      end
    end

    context 'when all previous periods are ongoing' do
      before do
        FactoryBot.create(:mentor_at_school_period, :ongoing, school: other_school, teacher:)
      end

      it 'returns false' do
        expect(registration_session.previous_school_closed_mentor_at_school_periods?).to be(false)
      end
    end
  end
end
