RSpec.describe Schools::RegisterECTWizard::ECT do
  subject(:ect) { described_class.new(store) }

  let(:author) { FactoryBot.create(:school_user, school_urn: school.urn) }
  let(:appropriate_body) { FactoryBot.create(:appropriate_body, :national) }
  let(:school) { FactoryBot.create(:school, :independent) }
  let(:store) do
    FactoryBot.build(:session_repository,
                     change_name: 'no',
                     corrected_name: nil,
                     date_of_birth: "11-10-1945",
                     email: "dusty@rhodes.com",
                     appropriate_body_id: appropriate_body.id,
                     training_programme: "school_led",
                     start_date: 'January 2025',
                     trn: "3002586",
                     trs_first_name: "Dusty",
                     trs_last_name: "Rhodes",
                     trs_date_of_birth: "1945-10-11",
                     trs_national_insurance_number: "OWAD23455",
                     working_pattern: "full_time")
  end

  describe '#active_record_at_school' do
    let(:teacher) { FactoryBot.create(:teacher, trn: '3002586') }

    context 'when the ECT has an ongoing ECT record at the school' do
      let!(:existing_ect_record) { FactoryBot.create(:ect_at_school_period, :active, school:, teacher:) }

      it 'returns the ECT record' do
        expect(ect.active_record_at_school(school.urn)).to eq(existing_ect_record)
      end
    end

    context 'when the ECT has no ongoing ECT record at the school' do
      let!(:existing_ect_record) { FactoryBot.create(:ect_at_school_period, school:, teacher:) }

      it 'returns nil' do
        expect(ect.active_record_at_school(school.urn)).to be_nil
      end
    end
  end

  describe '#active_at_school?' do
    let(:teacher) { FactoryBot.create(:teacher, trn: ect.trn) }

    it 'returns true if the ECT is active at the given school' do
      FactoryBot.create(:ect_at_school_period, :active, teacher:, school:)

      expect(ect.active_at_school?(school.urn)).to be_truthy
    end

    it 'returns false if the ECT is not at the given school' do
      FactoryBot.create(:ect_at_school_period, teacher:)

      expect(ect.active_at_school?(school.urn)).to be_falsey
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

  describe '#email' do
    it 'returns the email address' do
      expect(ect.email).to eq("dusty@rhodes.com")
    end
  end

  describe '#formatted_working_pattern' do
    it 'returns the formatted working pattern' do
      expect(ect.formatted_working_pattern).to eq('Full time')
    end
  end

  describe '#full_name' do
    it 'returns the full name of the ECT' do
      expect(ect.full_name).to eq("Dusty Rhodes")
    end

    context 'when corrected_name is set' do
      before do
        store.change_name = 'yes'
        store.corrected_name = 'Randy Marsh'
      end

      it 'returns the corrected_name as the full name' do
        expect(ect.full_name).to eq('Randy Marsh')
      end
    end
  end

  describe '#govuk_date_of_birth' do
    it 'formats the date of birth in the govuk format' do
      expect(ect.govuk_date_of_birth).to eq("11 October 1945")
    end
  end

  describe '#induction_completed?' do
    before do
      store.trs_induction_status = 'Passed'
    end

    context "when trs_induction_status is 'Passed'" do
      it 'returns true' do
        expect(ect).to be_induction_completed
      end
    end

    context "when trs_induction_status is not 'Passed'" do
      before do
        store.trs_induction_status = nil
      end

      it 'returns false' do
        expect(ect).not_to be_induction_completed
      end
    end
  end

  describe '#induction_exempt?' do
    before do
      store.trs_induction_status = 'Exempt'
    end

    context "when trs_induction_status is 'Exempt'" do
      it 'returns true' do
        expect(ect.induction_exempt?).to be_truthy
      end
    end

    context "when trs_induction_status is not 'Exempt'" do
      before do
        store.trs_induction_status = nil
      end

      it 'returns false' do
        expect(ect.induction_exempt?).to be_falsey
      end
    end
  end

  describe '#induction_failed?' do
    before do
      store.trs_induction_status = 'Failed'
    end

    context "when trs_induction_status is 'Failed'" do
      it 'returns true' do
        expect(ect).to be_induction_failed
      end
    end

    context "when trs_induction_status is not 'Failed'" do
      before do
        store.trs_induction_status = nil
      end

      it 'returns false' do
        expect(ect).not_to be_induction_failed
      end
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

  describe '#provider_led?' do
    before do
      store.training_programme = 'provider_led'
    end

    context "when training_programme is 'provider_led'" do
      it 'returns true' do
        expect(ect.provider_led?).to be_truthy
      end
    end

    context "when training_programme is not 'provider_led'" do
      before do
        store.training_programme = nil
      end

      it 'returns false' do
        expect(ect.provider_led?).to be_falsey
      end
    end
  end

  describe '#register!' do
    let(:teacher) { Teacher.first }
    let(:ect_at_school_period) { teacher.ect_at_school_periods.first }

    it "creates a new ECT at the given school" do
      expect(Teacher.find_by_trn(ect.trn)).to be_nil

      ect.register!(school, author:)

      expect(teacher.trn).to eq(ect.trn)
      expect(ect_at_school_period.school_id).to eq(school.id)
      expect(ect_at_school_period.started_on).to eq(Date.parse('January 2025'))
      expect(ect_at_school_period.email).to eq('dusty@rhodes.com')
      expect(ect_at_school_period.school_reported_appropriate_body_type).to eq('national')
    end
  end

  describe '#school_led?' do
    before do
      store.training_programme = 'school_led'
    end

    context "when training_programme is 'school_led'" do
      it 'returns true' do
        expect(ect.school_led?).to be_truthy
      end
    end

    context "when training_programme is not 'school_led'" do
      before do
        store.training_programme = nil
      end

      it 'returns false' do
        expect(ect.school_led?).to be_falsey
      end
    end
  end

  describe '#trn' do
    it 'returns the trn' do
      expect(ect.trn).to eq("3002586")
    end
  end

  describe '#trs_full_name' do
    it 'returns the full name of the ECT' do
      expect(ect.trs_full_name).to eq("Dusty Rhodes")
    end
  end

  describe '#trs_national_insurance_number' do
    it 'returns the national insurance number in trs' do
      expect(ect.trs_national_insurance_number).to eq("OWAD23455")
    end
  end

  describe '#working_pattern' do
    it 'returns the working pattern' do
      expect(ect.working_pattern).to eq("full_time")
    end
  end

  describe 'previous registration' do
    let(:teacher) { FactoryBot.create(:teacher) }
    let(:school) { FactoryBot.create(:school) }
    let(:ect_period) { FactoryBot.create(:ect_at_school_period, teacher:, school:, started_on: Date.new(2023, 12, 25), finished_on: Date.new(2024, 12, 25)) }

    before do
      store.trn = teacher.trn
    end

    describe '#induction_start_date' do
      context 'when the teacher has induction periods' do
        before do
          FactoryBot.create(:induction_period, teacher:, started_on: Date.new(2023, 6, 10), finished_on: Date.new(2023, 9, 30))
          FactoryBot.create(:induction_period, teacher:, started_on: Date.new(2023, 10, 1), finished_on: Date.new(2024, 4, 30))
          FactoryBot.create(:induction_period, teacher:, started_on: Date.new(2024, 5, 1), finished_on: Date.new(2024, 6, 30))
        end

        it 'returns the earliest started_on date' do
          expect(ect.induction_start_date).to eq(Date.new(2023, 6, 10))
        end
      end

      context 'when the teacher has no induction periods' do
        it 'returns nil' do
          expect(ect.induction_start_date).to be_nil
        end
      end
    end

    describe '#previous_appropriate_body_name' do
      context 'when the teacher has induction periods' do
        let!(:older_body) { FactoryBot.create(:appropriate_body, name: 'Older Body') }
        let!(:more_recent_body) { FactoryBot.create(:appropriate_body, name: 'More Recent Body') }

        before do
          FactoryBot.create(:induction_period, teacher:, started_on: Date.new(2023, 6, 10), finished_on: Date.new(2023, 9, 30), appropriate_body: older_body)
          FactoryBot.create(:induction_period, teacher:, started_on: Date.new(2023, 10, 1), finished_on: Date.new(2024, 4, 30), appropriate_body: more_recent_body)
        end

        it 'returns the name of the latest appropriate body by started_on' do
          expect(ect.previous_appropriate_body_name).to eq('More Recent Body')
        end
      end

      context 'when the teacher has no induction periods' do
        it 'returns nil' do
          expect(ect.previous_appropriate_body_name).to be_nil
        end
      end
    end

    describe '#previous_training_programme' do
      context 'when the teacher has ECTAtSchoolPeriods' do
        before do
          FactoryBot.create(:ect_at_school_period, teacher:, training_programme: :school_led, started_on: Date.new(2023, 10, 1), finished_on: Date.new(2023, 12, 1))
          FactoryBot.create(:ect_at_school_period, teacher:, training_programme: :provider_led, started_on: Date.new(2024, 1, 1), finished_on: Date.new(2024, 6, 1))
        end

        it 'returns the training programme from the latest ECTAtSchoolPeriod by started_on' do
          expect(ect.previous_training_programme).to eq('provider_led')
        end
      end

      context 'when the teacher has no ECTAtSchoolPeriods' do
        it 'returns nil' do
          expect(ect.previous_training_programme).to be_nil
        end
      end
    end

    describe '#previous_provider_led?' do
      context 'when the latest ECTAtSchoolPeriod is provider-led' do
        before do
          FactoryBot.create(:ect_at_school_period, teacher:, training_programme: :provider_led, started_on: Date.new(2024, 1, 1), finished_on: Date.new(2024, 6, 1))
        end

        it 'returns true' do
          expect(ect.previous_provider_led?).to be(true)
        end
      end

      context 'when the latest ECTAtSchoolPeriod is school-led' do
        before do
          FactoryBot.create(:ect_at_school_period, teacher:, training_programme: :school_led, started_on: Date.new(2024, 1, 1), finished_on: Date.new(2024, 6, 1))
        end

        it 'returns false' do
          expect(ect.previous_provider_led?).to be(false)
        end
      end

      context 'when there are no ECTAtSchoolPeriods' do
        it 'returns nil' do
          expect(ect.previous_provider_led?).to be_nil
        end
      end
    end

    describe '#previous_lead_provider_name' do
      let(:lead_provider) { FactoryBot.create(:lead_provider, name: 'Confirmed LP') }
      let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, lead_provider:) }
      let(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:) }

      before do
        FactoryBot.create(:training_period,
                          ect_at_school_period: ect_period,
                          school_partnership: FactoryBot.create(:school_partnership, lead_provider_delivery_partnership:),
                          started_on: Date.new(2024, 1, 1),
                          finished_on: Date.new(2024, 6, 1))
      end

      it 'returns the name of the lead provider from the latest training period' do
        expect(ect.previous_lead_provider_name).to eq('Confirmed LP')
      end
    end

    describe '#previous_delivery_partner_name' do
      let(:delivery_partner) { FactoryBot.create(:delivery_partner, name: 'DP') }
      let(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, delivery_partner:) }

      before do
        FactoryBot.create(:training_period,
                          ect_at_school_period: ect_period,
                          school_partnership: FactoryBot.create(:school_partnership, lead_provider_delivery_partnership:),
                          started_on: Date.new(2024, 1, 1),
                          finished_on: Date.new(2024, 6, 1))
      end

      it 'returns the name of the delivery partner from the latest training period' do
        expect(ect.previous_delivery_partner_name).to eq("DP")
      end
    end

    describe '#previous_school_name' do
      context 'when ECTAtSchoolPeriods exist' do
        let(:school_1) { FactoryBot.create(:school) }
        let(:school_2) { FactoryBot.create(:school) }

        before do
          FactoryBot.create(:gias_school, school: school_1, name: 'Old School')
          FactoryBot.create(:gias_school, school: school_2, name: 'Recent School')

          FactoryBot.create(:ect_at_school_period, teacher:, school: school_1, started_on: Date.new(2023, 1, 1), finished_on: Date.new(2023, 6, 30))
          FactoryBot.create(:ect_at_school_period, teacher:, school: school_2, started_on: Date.new(2023, 9, 1), finished_on: nil)
        end

        it 'returns the name of the most recent school by started_on' do
          expect(ect.previous_school_name).to eq('Recent School')
        end
      end

      context 'when no ECTAtSchoolPeriods exist' do
        it 'returns nil' do
          expect(ect.previous_school_name).to be_nil
        end
      end
    end

    describe '#lead_providers_within_contract_period' do
      let!(:contract_period) { FactoryBot.create(:contract_period, started_on: Date.new(2025, 1, 1), finished_on: Date.new(2025, 12, 31)) }
      let!(:lp_in) { FactoryBot.create(:lead_provider) }
      let!(:lp_out) { FactoryBot.create(:lead_provider) }

      before do
        FactoryBot.create(:active_lead_provider, contract_period:, lead_provider: lp_in)
        store.start_date = "1 March 2025"
      end

      it 'returns lead providers active in the contract period' do
        expect(ect.lead_providers_within_contract_period).to include(lp_in)
        expect(ect.lead_providers_within_contract_period).not_to include(lp_out)
      end

      context 'when no contract period matches the start_date' do
        before { store.start_date = nil }

        it 'returns an empty array' do
          expect(ect.lead_providers_within_contract_period).to eq([])
        end
      end
    end

    describe '#lead_provider_has_confirmed_partnership_for_contract_period?' do
      let(:lead_provider) { FactoryBot.create(:lead_provider, name: 'Confirmed LP') }
      let(:delivery_partner) { FactoryBot.create(:delivery_partner) }
      let(:school) { FactoryBot.create(:school) }
      let(:teacher) { FactoryBot.create(:teacher) }
      let(:contract_period) { FactoryBot.create(:contract_period, started_on: Date.new(2025, 1, 1), finished_on: Date.new(2025, 12, 31)) }

      context 'when everything is valid' do
        let!(:ect_period) do
          FactoryBot.create(
            :ect_at_school_period,
            :provider_led,
            :with_training_period,
            teacher:,
            school:,
            started_on: Date.new(2025, 3, 10),
            finished_on: Date.new(2025, 10, 10),
            lead_provider:,
            delivery_partner:,
            contract_period:
          )
        end

        it 'returns true' do
          expect(ect.lead_provider_has_confirmed_partnership_for_contract_period?(school)).to be true
        end
      end

      context 'when previous_lead_provider is nil' do
        # No ect_period or training period created
        it 'returns false' do
          expect(ect.lead_provider_has_confirmed_partnership_for_contract_period?(school)).to be false
        end
      end

      context 'when school is nil' do
        it 'returns false' do
          expect(ect.lead_provider_has_confirmed_partnership_for_contract_period?(nil)).to be false
        end
      end

      context 'when contract_start_date is nil' do
        before { store.start_date = nil }

        let!(:ect_period) do
          FactoryBot.create(
            :ect_at_school_period,
            :provider_led,
            :with_training_period,
            teacher:,
            school:,
            started_on: Date.new(2025, 3, 10),
            finished_on: Date.new(2025, 10, 10),
            lead_provider:,
            delivery_partner:,
            contract_period:
          )
        end

        it 'returns false' do
          expect(ect.lead_provider_has_confirmed_partnership_for_contract_period?(school)).to be false
        end
      end

      context 'when no school partnership exists in the contract period' do
        let!(:other_contract_period) do
          FactoryBot.create(:contract_period, started_on: Date.new(2024, 1, 1), finished_on: Date.new(2024, 12, 31))
        end

        let!(:ect_period) do
          FactoryBot.create(
            :ect_at_school_period,
            :provider_led,
            :with_training_period,
            teacher:,
            school:,
            started_on: Date.new(2025, 3, 10),
            finished_on: Date.new(2025, 10, 10),
            lead_provider:,
            delivery_partner:,
            contract_period: other_contract_period
          )
        end

        it 'returns false' do
          expect(ect.lead_provider_has_confirmed_partnership_for_contract_period?(school)).to be false
        end
      end

      context 'when all inputs are nil' do
        let(:dummy_store) { FactoryBot.build(:session_repository, start_date: nil, trn: nil) }

        it 'returns false' do
          expect(described_class.new(dummy_store).lead_provider_has_confirmed_partnership_for_contract_period?(nil)).to be false
        end
      end
    end

    describe '#previous_eoi_lead_provider_name' do
      let(:school) { FactoryBot.create(:school) }

      context 'when there is a previous training period with an EOI' do
        let(:lead_provider) { FactoryBot.create(:lead_provider, name: "Team Kurenai") }
        let(:expression_of_interest) { FactoryBot.create(:active_lead_provider, lead_provider:) }
        let(:teacher) { FactoryBot.create(:teacher) }

        let!(:ect_period) do
          FactoryBot.create(
            :ect_at_school_period,
            :provider_led,
            school:,
            teacher:,
            started_on: Date.new(2025, 3, 10)
          )
        end

        let!(:training_period) do
          FactoryBot.create(
            :training_period,
            :for_ect,
            ect_at_school_period: ect_period,
            started_on: Date.new(2025, 3, 10),
            expression_of_interest:
          )
        end

        it 'returns the name of the EOI lead provider for the previous training period' do
          expect(ect.previous_eoi_lead_provider_name).to eq("Team Kurenai")
        end
      end

      context 'when there is no previous training period' do
        it 'returns nil' do
          expect(ect.previous_eoi_lead_provider_name).to be_nil
        end
      end

      context 'when the previous training period has no EOI' do
        let(:teacher) { FactoryBot.create(:teacher) }

        let!(:ect_period) do
          FactoryBot.create(
            :ect_at_school_period,
            :provider_led,
            school:,
            teacher:,
            started_on: Date.new(2025, 3, 10)
          )
        end

        let!(:training_period) do
          FactoryBot.create(
            :training_period,
            :for_ect,
            ect_at_school_period: ect_period,
            started_on: Date.new(2025, 3, 10),
            expression_of_interest: nil
          )
        end

        it 'returns nil' do
          expect(ect.previous_eoi_lead_provider_name).to be_nil
        end
      end
    end
  end
end
