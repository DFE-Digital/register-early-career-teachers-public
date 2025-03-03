RSpec.describe Schools::RegisterECTWizard::ECT do
  subject(:ect) { described_class.new(store) }

  let(:school) { FactoryBot.create(:school) }
  let(:store) do
    FactoryBot.build(:session_repository,
                     corrected_name: nil,
                     date_of_birth: "11-10-1945",
                     email: "dusty@rhodes.com",
                     programme_type: "pokemon_led",
                     start_date: 'January 2025',
                     trn: "3002586",
                     trs_first_name: "Dusty",
                     trs_last_name: "Rhodes",
                     trs_date_of_birth: "1945-10-11",
                     trs_national_insurance_number: "OWAD23455",
                     working_pattern: "full_time")
  end

  describe '#email' do
    it 'returns the email address' do
      expect(ect.email).to eq("dusty@rhodes.com")
    end
  end

  describe '#full_name' do
    it 'returns the full name of the ECT' do
      expect(ect.full_name).to eq("Dusty Rhodes")
    end

    context 'when corrected_name is set' do
      before do
        store.corrected_name = 'Randy Marsh'
      end

      it 'returns the corrected_name as the full name' do
        expect(ect.full_name).to eq('Randy Marsh')
      end
    end
  end

  describe '#trs_full_name' do
    it 'returns the full name of the ECT' do
      expect(ect.trs_full_name).to eq("Dusty Rhodes")
    end
  end

  describe '#govuk_date_of_birth' do
    it 'formats the date of birth in the govuk format' do
      expect(ect.govuk_date_of_birth).to eq("11 October 1945")
    end
  end

  describe '#in_trs?' do
    context "when trs_first_name has been set" do
      it 'returns true' do
        expect(ect.in_trs?).to be_truthy
      end
    end

    context "when trs_first_name has not been set or is blank" do
      before do
        store.trs_first_name = nil
      end

      it 'returns false' do
        expect(ect.in_trs?).to be_falsey
      end
    end
  end

  describe '#matches_trs_dob?' do
    context "when date_of_birth is blank" do
      before do
        store.date_of_birth = nil
      end

      it 'returns false' do
        expect(ect.matches_trs_dob?).to be_falsey
      end
    end

    context "when trs_date_of_birth is blank" do
      before do
        store.trs_date_of_birth = nil
      end

      it 'returns false' do
        expect(ect.matches_trs_dob?).to be_falsey
      end
    end

    context "when date_of_birth and trs_date_of_birth are different dates" do
      before do
        store.date_of_birth = "1935-10-11"
      end

      it 'returns false' do
        expect(ect.matches_trs_dob?).to be_falsey
      end
    end

    context "when date_of_birth and trs_date_of_birth are the same date" do
      it 'returns true' do
        expect(ect.matches_trs_dob?).to be_truthy
      end
    end
  end

  describe '#trn' do
    it 'returns the trn' do
      expect(ect.trn).to eq("3002586")
    end
  end

  describe '#working_pattern' do
    it 'returns the working pattern' do
      expect(ect.working_pattern).to eq("full_time")
    end
  end

  describe '#trs_national_insurance_number' do
    it 'returns the national insurance number in trs' do
      expect(ect.trs_national_insurance_number).to eq("OWAD23455")
    end
  end

  describe '#formatted_programme_type' do
    it 'returns the formatted programme type' do
      expect(ect.formatted_programme_type).to eq('Pokemon-led')
    end
  end

  describe '#formatted_working_pattern' do
    it 'returns the formatted working pattern' do
      expect(ect.formatted_working_pattern).to eq('Full time')
    end
  end

  describe '#register!' do
    let(:teacher) { Teacher.first }
    let(:ect_at_school_period) { teacher.ect_at_school_periods.first }

    it "creates a new ECT at the given school" do
      expect(Teacher.find_by_trn(ect.trn)).to be_nil

      ect.register!(school)

      expect(teacher.trn).to eq(ect.trn)
      expect(ect_at_school_period.school_id).to eq(school.id)
      expect(ect_at_school_period.started_on).to eq(Date.parse('January 2025'))
      expect(ect_at_school_period.email).to eq('dusty@rhodes.com')
    end
  end

  describe '#formatted_appropriate_body_name' do
    context "when appropriate_body_type is 'teaching_induction_panel'" do
      before do
        store.appropriate_body_type = 'teaching_induction_panel'
      end

      specify do
        expect(ect.formatted_appropriate_body_name).to eq('Independent Schools Teacher Induction Panel (ISTIP)')
      end
    end

    context "when appropriate_body_type is not 'teaching_induction_panel'" do
      before do
        FactoryBot.create(:appropriate_body, id: 1, name: 'Another body')
        store.appropriate_body_type = 'teaching_school_hub'
        store.appropriate_body_id = '1'
      end

      it 'returns the name' do
        expect(ect.formatted_appropriate_body_name).to eq('Another body')
      end
    end
  end

  describe '#active_at_school?' do
    let(:teacher) { FactoryBot.create(:teacher, trn: ect.trn) }

    it 'returns true if the ECT is registered at the given school' do
      FactoryBot.create(:ect_at_school_period, :active, teacher:, school:)

      expect(ect.active_at_school?(school:)).to be_truthy
    end

    it 'returns false if the ECT is not registered at the given school' do
      FactoryBot.create(:ect_at_school_period, teacher:)

      expect(ect.active_at_school?(school:)).to be_falsey
    end
  end

  describe '#cant_use_email?' do
    let(:teacher_email_service) { instance_double(Schools::TeacherEmail) }

    before do
      allow(Schools::TeacherEmail).to receive(:new).with(email: ect.email, trn: ect.trn).and_return(teacher_email_service)
    end

    context "when the email is used in an ongoing school period" do
      before { allow(teacher_email_service).to receive(:is_currently_used?).and_return(true) }

      it "returns true" do
        expect(subject.cant_use_email?).to be true
      end
    end

    context "when the email is not used in an ongoing school period" do
      before { allow(teacher_email_service).to receive(:is_currently_used?).and_return(false) }

      it "returns false" do
        expect(subject.cant_use_email?).to be false
      end
    end
  end
end
