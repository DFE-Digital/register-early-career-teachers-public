describe "Two ECT induction records (with the second being at a different school)" do
  subject(:teacher) { Teacher.find_by(trn: ecf1_teacher_profile.trn) }

  let(:user_created_at) { 3.years.ago.round }
  let(:ecf1_participant_profile) { FactoryBot.create(:migration_participant_profile, :ect) }

  # ECF1 data
  let(:ecf1_cohort) { FactoryBot.create(:migration_cohort, start_year: 2022) }
  let(:ecf1_schedule) { FactoryBot.create(:migration_schedule, cohort: ecf1_cohort, schedule_identifier: "ecf-standard-september") }
  let(:ecf1_school_1) { ecf1_school_cohort_1.school }
  let(:ecf1_school_2) { ecf1_school_cohort_2.school }
  let(:ecf1_school_cohort_1) { FactoryBot.create(:migration_school_cohort, cohort: ecf1_cohort) }
  let(:ecf1_school_cohort_2) { FactoryBot.create(:migration_school_cohort, cohort: ecf1_cohort) }
  let(:ecf1_lead_provider_1) { ecf1_induction_programme_1.partnership.lead_provider }
  let(:ecf1_lead_provider_2) { ecf1_induction_programme_2.partnership.lead_provider }
  let(:ecf1_delivery_partner_1) { ecf1_induction_programme_1.partnership.delivery_partner }
  let(:ecf1_delivery_partner_2) { ecf1_induction_programme_2.partnership.delivery_partner }

  # - first record
  let!(:ecf1_induction_programme_1) { FactoryBot.create(:migration_induction_programme, :provider_led, school_cohort: ecf1_school_cohort_1) }
  let!(:ecf1_induction_record_1) do
    FactoryBot.create(
      :migration_induction_record,
      participant_profile: ecf1_participant_profile,
      induction_programme: ecf1_induction_programme_1,
      updated_at: 3.years.ago.round,
      start_date: 4.years.ago.round,
      end_date: 3.years.ago.round,
      induction_status: "leaving",
      training_status: "active",
      schedule: ecf1_schedule
    )
  end

  # - second record
  let!(:ecf1_induction_programme_2) { FactoryBot.create(:migration_induction_programme, :provider_led, school_cohort: ecf1_school_cohort_2) }
  let!(:ecf1_induction_record_2) do
    FactoryBot.create(
      :migration_induction_record,
      participant_profile: ecf1_participant_profile,
      induction_programme: ecf1_induction_programme_2,
      updated_at: 1.day.ago.round,
      start_date: 2.years.ago.round,
      end_date: nil,
      school_transfer: true,
      induction_status: "active",
      training_status: "active",
      schedule: ecf1_schedule
    )
  end

  let(:ecf1_teacher_profile) { ecf1_participant_profile.teacher_profile }

  # ECF2 data
  let!(:ecf2_gias_school) { FactoryBot.create(:gias_school, :with_school, urn: ecf1_school_1.urn) }
  let(:ecf2_school) { ecf2_gias_school.school }
  let!(:ecf2_gias_school_2) { FactoryBot.create(:gias_school, :with_school, urn: ecf1_school_2.urn) }
  let(:ecf2_school_2) { ecf2_gias_school_2.school }
  let!(:ecf2_contract_period) { FactoryBot.create(:contract_period, year: ecf1_cohort.start_year) }

  let!(:ecf2_lead_provider_1) { FactoryBot.create(:lead_provider, name: ecf1_lead_provider_1.name, ecf_id: ecf1_lead_provider_1.id) }
  let!(:ecf2_delivery_partner_1) { FactoryBot.create(:delivery_partner, name: ecf1_delivery_partner_1.name, api_id: ecf1_delivery_partner_1.id) }

  let!(:ecf2_lead_provider_2) { FactoryBot.create(:lead_provider, name: ecf1_lead_provider_2.name, ecf_id: ecf1_lead_provider_2.id) }
  let!(:ecf2_delivery_partner_2) { FactoryBot.create(:delivery_partner, name: ecf1_delivery_partner_2.name, api_id: ecf1_delivery_partner_2.id) }

  # - first school partnership
  let!(:ecf2_active_lead_provider_1) { FactoryBot.create(:active_lead_provider, lead_provider: ecf2_lead_provider_1, contract_period: ecf2_contract_period) }
  let!(:ecf2_lead_provider_delivery_partnership_1) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider: ecf2_active_lead_provider_1, delivery_partner: ecf2_delivery_partner_1) }
  let!(:ecf2_school_partnership_1) { FactoryBot.create(:school_partnership, school: ecf2_school, lead_provider_delivery_partnership: ecf2_lead_provider_delivery_partnership_1) }

  # - second school partnership
  let!(:ecf2_active_lead_provider_2) { FactoryBot.create(:active_lead_provider, lead_provider: ecf2_lead_provider_2, contract_period: ecf2_contract_period) }
  let!(:ecf2_lead_provider_delivery_partnership_2) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider: ecf2_active_lead_provider_2, delivery_partner: ecf2_delivery_partner_2) }
  let!(:ecf2_school_partnership_2) { FactoryBot.create(:school_partnership, school: ecf2_school_2, lead_provider_delivery_partnership: ecf2_lead_provider_delivery_partnership_2) }

  let!(:ecf2_schedule) { FactoryBot.create(:schedule, contract_period: ecf2_contract_period, identifier: ecf1_schedule.schedule_identifier) }

  # Conversion objects
  let(:ecf1_teacher_history) { ECF1TeacherHistory.build(teacher_profile: ecf1_teacher_profile) }
  let(:teacher_history_converter) { TeacherHistoryConverter.new(ecf1_teacher_history:, migration_mode:) }

  before do
    ecf2_teacher_history = teacher_history_converter.convert_to_ecf2!
    ecf2_teacher_history.save_all_ect_data!
  end

  context "when in latest_induction_records mode (economy)" do
    let(:migration_mode) { :latest_induction_records }

    it "creates the teacher record" do
      expect(teacher).to be_persisted
      expect(teacher.migration_mode).to eq "latest_induction_records"
    end

    it "creates two ect_at_school_periods" do
      expect(teacher.ect_at_school_periods.count).to be(2)
    end

    it "creates one training_period on each ect_at_school_periods" do
      expect(teacher.ect_at_school_periods[0].training_periods.count).to be(1)
      expect(teacher.ect_at_school_periods[1].training_periods.count).to be(1)
    end

    it "sets the api_transfer_updated_at correctly" do
      expect(teacher.ect_at_school_periods[0].training_periods.first.api_transfer_updated_at).to eq(ecf1_induction_record_1.updated_at)
      expect(teacher.ect_at_school_periods[1].training_periods.first.api_transfer_updated_at).to eq(ecf1_induction_record_2.updated_at)
    end
  end

  context "when in all_induction_records mode (premium)" do
    let(:migration_mode) { :all_induction_records }

    it "creates the teacher record" do
      expect(teacher).to be_persisted
      expect(teacher.migration_mode).to eq "all_induction_records"
    end

    it "creates two ect_at_school_periods" do
      expect(teacher.ect_at_school_periods.count).to be(2)
    end

    it "creates one training_period on each ect_at_school_periods" do
      expect(teacher.ect_at_school_periods[0].training_periods.count).to be(1)
      expect(teacher.ect_at_school_periods[1].training_periods.count).to be(1)
    end

    it "sets the api_transfer_updated_at correctly" do
      expect(teacher.ect_at_school_periods[0].training_periods.first.api_transfer_updated_at).to eq(ecf1_induction_record_1.updated_at)
      expect(teacher.ect_at_school_periods[1].training_periods.first.api_transfer_updated_at).to eq(ecf1_induction_record_2.updated_at)
    end
  end
end
