describe Schools::RegisterMentorWizard::Wizard do
  let(:current_step) { :find_mentor }
  let(:ect_teacher) { FactoryBot.create(:teacher, trn: "7654321") }
  let(:ect) { FactoryBot.create(:ect_at_school_period, :active, teacher: ect_teacher) }
  let(:ect_id) { ect.id }
  let(:mentor_trn) { "1234567" }
  let(:mentor_date_of_birth) { "1977-02-03" }
  let(:prohibited_from_teaching) { false }
  let(:school_urn) { '1212121' }
  let(:trs_date_of_birth) { "1977-02-03" }
  let(:trs_first_name) { "Mentor" }
  let(:trs_last_name) { "LastName" }
  let(:wizard) { FactoryBot.build(:register_mentor_wizard, current_step:, store:, ect_id:) }

  describe '#allowed_steps' do
    subject { wizard.allowed_steps }

    context 'when no data has been set yet' do
      let(:store) { FactoryBot.build(:session_repository, school_urn:) }

      it { is_expected.to eq(%i[no_trn find_mentor]) }
    end

    context 'when only TRN has been set' do
      let(:store) { FactoryBot.build(:session_repository, trn: mentor_trn, school_urn:) }

      described_class.steps.first.each_key do |step|
        context "when the requested step is #{step}" do
          let(:current_step) { step }

          it { is_expected.to eq(%i[no_trn find_mentor]) }
        end
      end
    end

    context 'when only TRN and DoB have been set' do
      let(:store) do
        FactoryBot.build(:session_repository,
                         school_urn:,
                         trn: mentor_trn,
                         date_of_birth: mentor_date_of_birth,
                         prohibited_from_teaching:,
                         trs_date_of_birth:,
                         trs_first_name:,
                         trs_last_name:)
      end

      context 'when the mentor has not been found in TRS' do
        let(:prohibited_from_teaching) { nil }
        let(:trs_date_of_birth) { nil }
        let(:trs_first_name) { nil }
        let(:trs_last_name) { nil }

        it { is_expected.to eq(%i[no_trn find_mentor trn_not_found]) }
      end

      context 'when the mentor trn has matched that of the ECT' do
        let(:mentor_trn) { ect.trn }

        it { is_expected.to eq(%i[no_trn find_mentor cannot_mentor_themself]) }
      end

      context "when the date of birth didn't match that on TRS" do
        let(:mentor_date_of_birth) { "2000-01-01" }

        it { is_expected.to eq(%i[no_trn find_mentor national_insurance_number]) }
      end

      context 'when the mentor is already active at the school' do
        let(:mentor_teacher) { FactoryBot.create(:teacher, trn: mentor_trn) }
        let(:active_mentor_period) { FactoryBot.create(:mentor_at_school_period, :active, teacher: mentor_teacher) }
        let(:school_urn) { active_mentor_period.school.urn }

        it { is_expected.to eq(%i[no_trn find_mentor already_active_at_school]) }
      end

      context 'when the mentor is prohibited from teaching' do
        let(:prohibited_from_teaching) { true }

        it { is_expected.to eq(%i[no_trn find_mentor cannot_register_mentor]) }
      end

      context 'when the mentor is not prohibited from teaching' do
        it { is_expected.to eq(%i[no_trn find_mentor review_mentor_details]) }
      end
    end

    context 'when only TRN, DoB and Nino have been set' do
      let(:mentor_date_of_birth) { "2000-01-01" }
      let(:store) do
        FactoryBot.build(:session_repository,
                         school_urn:,
                         trn: mentor_trn,
                         date_of_birth: mentor_date_of_birth,
                         prohibited_from_teaching:,
                         trs_date_of_birth:,
                         trs_first_name:,
                         trs_last_name:,
                         national_insurance_number: 'ZZ123456A')
      end

      context 'when the mentor has not been found in TRS' do
        let(:prohibited_from_teaching) { nil }
        let(:trs_date_of_birth) { nil }
        let(:trs_first_name) { nil }
        let(:trs_last_name) { nil }

        it { is_expected.to eq(%i[no_trn find_mentor national_insurance_number not_found]) }
      end

      context 'when the mentor is already active at the school' do
        let(:mentor_teacher) { FactoryBot.create(:teacher, trn: mentor_trn) }
        let(:active_mentor_period) { FactoryBot.create(:mentor_at_school_period, :active, teacher: mentor_teacher) }
        let(:school_urn) { active_mentor_period.school.urn }

        it { is_expected.to eq(%i[no_trn find_mentor national_insurance_number already_active_at_school]) }
      end

      context 'when the mentor is prohibited from teaching' do
        let(:prohibited_from_teaching) { true }

        it { is_expected.to eq(%i[no_trn find_mentor national_insurance_number cannot_register_mentor]) }
      end

      context 'when the mentor is not prohibited from teaching' do
        it { is_expected.to eq(%i[no_trn find_mentor national_insurance_number review_mentor_details]) }
      end
    end

    context 'when only TRN, DoB and already active at school have been set' do
      let(:mentor_teacher) { FactoryBot.create(:teacher, trn: mentor_trn) }
      let(:active_mentor_period) { FactoryBot.create(:mentor_at_school_period, :active, teacher: mentor_teacher) }
      let(:school_urn) { active_mentor_period.school.urn }
      let(:already_active_at_school) { true }
      let(:store) do
        FactoryBot.build(:session_repository,
                         school_urn:,
                         trn: mentor_trn,
                         date_of_birth: mentor_date_of_birth,
                         prohibited_from_teaching:,
                         trs_date_of_birth:,
                         trs_first_name:,
                         trs_last_name:,
                         already_active_at_school:)
      end

      it { is_expected.to eq(%i[confirmation]) }
    end

    context 'when only TRN, DoB, Nino and already active at school have been set' do
      let(:mentor_date_of_birth) { "2000-01-01" }
      let(:mentor_teacher) { FactoryBot.create(:teacher, trn: mentor_trn) }
      let(:active_mentor_period) { FactoryBot.create(:mentor_at_school_period, :active, teacher: mentor_teacher) }
      let(:school_urn) { active_mentor_period.school.urn }
      let(:already_active_at_school) { true }
      let(:store) do
        FactoryBot.build(:session_repository,
                         school_urn:,
                         trn: mentor_trn,
                         date_of_birth: mentor_date_of_birth,
                         prohibited_from_teaching:,
                         trs_date_of_birth:,
                         trs_first_name:,
                         trs_last_name:,
                         national_insurance_number: 'ZZ123456A',
                         already_active_at_school:)
      end

      it { is_expected.to eq(%i[confirmation]) }
    end

    context 'when only TRN, DoB and change name (and maybe corrected name) have been set' do
      let(:store) do
        FactoryBot.build(:session_repository,
                         school_urn:,
                         trn: mentor_trn,
                         date_of_birth: mentor_date_of_birth,
                         prohibited_from_teaching:,
                         trs_date_of_birth:,
                         trs_first_name:,
                         trs_last_name:,
                         change_name: 'no')
      end

      it { is_expected.to eq(%i[no_trn find_mentor review_mentor_details email_address]) }
    end

    context 'when only TRN, DoB, Nino and change name (and maybe corrected name) have been set' do
      let(:mentor_date_of_birth) { "2000-01-01" }
      let(:store) do
        FactoryBot.build(:session_repository,
                         school_urn:,
                         trn: mentor_trn,
                         date_of_birth: mentor_date_of_birth,
                         national_insurance_number: 'ZZ123456A',
                         prohibited_from_teaching:,
                         trs_date_of_birth:,
                         trs_first_name:,
                         trs_last_name:,
                         change_name: 'yes',
                         corrected_name: 'Mentor CorrectedName')
      end

      it { is_expected.to eq(%i[no_trn find_mentor national_insurance_number review_mentor_details email_address]) }
    end

    context 'when only TRN, DoB, change name (and maybe corrected name) and email have been set' do
      let(:store) do
        FactoryBot.build(:session_repository,
                         school_urn:,
                         trn: mentor_trn,
                         date_of_birth: mentor_date_of_birth,
                         prohibited_from_teaching:,
                         trs_date_of_birth:,
                         trs_first_name:,
                         trs_last_name:,
                         change_name: 'no',
                         email: 'any@email.address')
      end

      context 'when the email is in use by another participant' do
        before { allow(wizard.mentor).to receive(:cant_use_email?).and_return(true) }

        it { is_expected.to eq(%i[no_trn find_mentor review_mentor_details email_address cant_use_email]) }
      end

      context 'when the mentor is eligible for funding' do
        before { allow(wizard.mentor).to receive(:funding_available?).and_return(true) }

        it do
          expect(subject).to eq(%i[no_trn
                                   find_mentor
                                   review_mentor_details
                                   email_address
                                   review_mentor_eligibility
                                   change_mentor_details
                                   change_email_address
                                   check_answers])
        end
      end
    end

    context 'when only TRN, DoB, Nino, change name (and maybe corrected name) and email address have been set' do
      let(:mentor_date_of_birth) { "2000-01-01" }
      let(:store) do
        FactoryBot.build(:session_repository,
                         school_urn:,
                         trn: mentor_trn,
                         date_of_birth: mentor_date_of_birth,
                         national_insurance_number: 'ZZ123456A',
                         prohibited_from_teaching:,
                         trs_date_of_birth:,
                         trs_first_name:,
                         trs_last_name:,
                         change_name: 'yes',
                         corrected_name: 'Mentor CorrectedName',
                         email: 'any@email.address')
      end

      context 'when the email is in use by another participant' do
        before { allow(wizard.mentor).to receive(:cant_use_email?).and_return(true) }

        it { is_expected.to eq(%i[no_trn find_mentor national_insurance_number review_mentor_details email_address cant_use_email]) }
      end

      context 'when the mentor is eligible for funding' do
        before { allow(wizard.mentor).to receive(:funding_available?).and_return(true) }

        it do
          expect(subject).to eq(%i[no_trn
                                   find_mentor
                                   national_insurance_number
                                   review_mentor_details
                                   email_address
                                   review_mentor_eligibility
                                   change_mentor_details
                                   change_email_address
                                   check_answers])
        end
      end
    end
  end

  describe '#allowed_step_path' do
    let(:store) { FactoryBot.build(:session_repository, school_urn:) }
    subject { wizard.allowed_step_path }

    before { allow(wizard).to receive(:allowed_steps).and_return(%i[find_mentor check_answers]) }

    it "returns the path to the last allowed one" do
      expect(subject).to eq("/school/register-mentor/check-answers")
    end
  end
end
