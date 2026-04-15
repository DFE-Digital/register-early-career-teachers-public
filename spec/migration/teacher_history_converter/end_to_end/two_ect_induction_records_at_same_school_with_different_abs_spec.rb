describe "Two ECT induction records at the same school with different appropriate bodies" do
  subject(:teacher) { Teacher.find_by(trn: ecf1_teacher_profile.trn) }

  let(:user_created_at) { 3.years.ago.round }
  let(:ecf1_participant_profile) { FactoryBot.create(:migration_participant_profile, :ect) }

  # ECF1 data
  let(:ecf1_school) { FactoryBot.create(:ecf_migration_school) }
  let(:ecf1_cohort) { FactoryBot.create(:migration_cohort, start_year: 2022) }
  let(:ecf1_school_cohort) { FactoryBot.create(:migration_school_cohort, school: ecf1_school, cohort: ecf1_cohort) }
  let(:ecf1_schedule) { FactoryBot.create(:migration_schedule, cohort: ecf1_cohort, schedule_identifier: "ecf-standard-september") }

  let(:ecf1_lead_provider) { FactoryBot.create(:migration_lead_provider, :ambition) }
  let(:ecf1_delivery_partner) { FactoryBot.create(:migration_delivery_partner) }
  let(:ecf1_partnership) { FactoryBot.create(:migration_partnership, lead_provider: ecf1_lead_provider, delivery_partner: ecf1_delivery_partner, cohort: ecf1_cohort, school: ecf1_school) }

  # - first record
  # - ecf1_id: 4a058289-5710-4077-b89d-c64019929a6b
  #   ecf1_name: Wirral
  #   type: local_authority
  #   ecf2_id: 152
  #   ecf2_name: Wirral LA
  let(:ecf1_appropriate_body_1) { FactoryBot.create(:migration_appropriate_body, id: "4a058289-5710-4077-b89d-c64019929a6b") } # Wirral

  let!(:ecf1_induction_programme_1) { FactoryBot.create(:migration_induction_programme, :provider_led, school_cohort: ecf1_school_cohort, partnership: ecf1_partnership) }
  let!(:ecf1_induction_record_1) do
    FactoryBot.create(
      :migration_induction_record,
      participant_profile: ecf1_participant_profile,
      induction_programme: ecf1_induction_programme_1,
      created_at: 18.hours.ago.round,
      start_date: 4.years.ago.round,
      end_date: 3.years.ago.round,
      training_status: "active",
      schedule: ecf1_schedule,
      appropriate_body: ecf1_appropriate_body_1
    )
  end

  # - ecf1_id: 1fcd139c-2f61-4b57-ad93-cd57abbf1b61
  #   ecf1_name: Worcestershire
  #   type: local_authority
  #   ecf2_id: 79
  #   ecf2_name: Worcestershire LA
  let(:ecf1_appropriate_body_2) { FactoryBot.create(:migration_appropriate_body, id: "1fcd139c-2f61-4b57-ad93-cd57abbf1b61") } # Worcestershire

  let!(:ecf1_induction_programme_2) { FactoryBot.create(:migration_induction_programme, :provider_led, school_cohort: ecf1_school_cohort, partnership: ecf1_partnership) }
  let!(:ecf1_induction_record_2) do
    FactoryBot.create(
      :migration_induction_record,
      participant_profile: ecf1_participant_profile,
      induction_programme: ecf1_induction_programme_2,
      created_at: 2.years.ago.round,
      start_date: 2.years.ago.round,
      end_date: 1.year.ago.round,
      training_status: "active",
      schedule: ecf1_schedule,
      appropriate_body: ecf1_appropriate_body_2
    )
  end

  let!(:ecf1_induction_record_3) do
    FactoryBot.create(
      :migration_induction_record,
      participant_profile: ecf1_participant_profile,
      induction_programme: ecf1_induction_programme_2,
      created_at: 2.years.ago.round,
      start_date: 11.months.ago.round,
      end_date: nil,
      training_status: "active",
      schedule: ecf1_schedule,
      appropriate_body: ecf1_appropriate_body_3
    )
  end

  let(:ecf1_teacher_profile) { ecf1_participant_profile.participant_identity.user.teacher_profile }

  # ECF2 data
  let!(:ecf2_gias_school) { FactoryBot.create(:gias_school, :with_school, urn: ecf1_school.urn) }
  let(:ecf2_school) { ecf2_gias_school.school }
  let!(:ecf2_contract_period) { FactoryBot.create(:contract_period, year: ecf1_cohort.start_year) }

  let!(:ecf2_lead_provider) { FactoryBot.create(:lead_provider, name: ecf1_lead_provider.name, ecf_id: ecf1_lead_provider.id) }
  let!(:ecf2_delivery_partner) { FactoryBot.create(:delivery_partner, name: ecf1_delivery_partner.name, api_id: ecf1_delivery_partner.id) }

  let!(:ecf2_active_lead_provider) { FactoryBot.create(:active_lead_provider, lead_provider: ecf2_lead_provider, contract_period: ecf2_contract_period) }
  let!(:ecf2_lead_provider_delivery_partnership_1) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider: ecf2_active_lead_provider, delivery_partner: ecf2_delivery_partner) }
  let!(:ecf2_school_partnership) { FactoryBot.create(:school_partnership, school: ecf2_school, lead_provider_delivery_partnership: ecf2_lead_provider_delivery_partnership_1) }

  let!(:ecf2_appropriate_body_wirral) { FactoryBot.create(:appropriate_body_period, id: 152) } # Wirral
  let!(:ecf2_appropriate_body_worcestershire) { FactoryBot.create(:appropriate_body_period, id: 79) } # Worcestershire
  let!(:ecf2_appropriate_body_swindon) { FactoryBot.create(:appropriate_body_period, id: 172) } # Swindon

  let!(:ecf2_schedule) { FactoryBot.create(:schedule, contract_period: ecf2_contract_period, identifier: ecf1_schedule.schedule_identifier) }

  # Conversion objects
  let(:ecf1_teacher_history) { ECF1TeacherHistory.build(teacher_profile: ecf1_teacher_profile) }
  let(:teacher_history_converter) { TeacherHistoryConverter.new(ecf1_teacher_history:, migration_mode:) }

  before do
    ecf2_teacher_history = teacher_history_converter.convert_to_ecf2!
    ecf2_teacher_history.save_all_ect_data!
  end

  context "when in all_induction_records mode (premium)" do
    let(:ecf1_appropriate_body_3) { nil }
    let(:migration_mode) { :all_induction_records }

    it "creates the teacher record" do
      expect(teacher).to be_persisted
      expect(teacher.migration_mode).to eq "all_induction_records"
    end

    it "creates one ect_at_school_period" do
      expect(teacher.ect_at_school_periods.count).to eq(1)
    end

    context "when the third induction record has no appropriate body" do
      it "has the appropriate body from the second induction record" do
        expect(teacher.ect_at_school_periods[0].school_reported_appropriate_body).to eql(ecf2_appropriate_body_worcestershire)
      end
    end

    context "when the third induction record has an appropriate body" do
      # - ecf1_id: 5bd3d584-30fd-4960-b20f-ce8d42710caf
      #   ecf1_name: Swindon
      #   type: local_authority
      #   ecf2_id: 172
      #   ecf2_name: Swindon LA
      let(:ecf1_appropriate_body_3) { FactoryBot.create(:migration_appropriate_body, id: "5bd3d584-30fd-4960-b20f-ce8d42710caf") } # Swindon

      it "has the appropriate body from the third induction record" do
        expect(teacher.ect_at_school_periods[0].school_reported_appropriate_body).to eql(ecf2_appropriate_body_swindon)
      end
    end
  end
end
