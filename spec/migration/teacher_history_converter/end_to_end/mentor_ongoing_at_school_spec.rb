describe "Mentor at a school with a few induction records" do
  ######
  #
  #  ┌────────┐  ┌────────┐  ┌────────┐  ┌────────┐  ┌────────┐
  #  │ Active │->| Active |->| Active |->| Active |->| Active |---->
  #  └────────┘  └────────┘  └────────┘  └────────┘  └────────┘
  #
  # Should become these periods:
  #
  #  ┌─────────────────────────────────────┐
  #  │       Mentor At School Period       |---->
  #  └─────────────────────────────────────┘
  #  ┌─────────────────────────────────────┐
  #  │          Training Period            │---->
  #  └─────────────────────────────────────┘
  #

  subject(:teacher) { Teacher.find_by(trn: ecf1_teacher_profile.trn) }

  let(:user_created_at) { Time.zone.local(2023, 1, 1, 12, 50, 43) }
  let(:ecf1_participant_profile) { FactoryBot.create(:migration_participant_profile, :mentor) }

  # ECF1 data
  let(:ecf1_school) { FactoryBot.create(:ecf_migration_school) }
  let(:ecf1_cohort) { FactoryBot.create(:migration_cohort, start_year: 2022) }
  let(:ecf1_school_cohort) { FactoryBot.create(:migration_school_cohort, school: ecf1_school, cohort: ecf1_cohort) }
  let(:ecf1_schedule) { FactoryBot.create(:migration_schedule, cohort: ecf1_cohort, schedule_identifier: "ecf-standard-september") }

  # - first record
  let(:ecf1_lead_provider) { FactoryBot.create(:migration_lead_provider, :ambition) }
  let(:ecf1_delivery_partner) { FactoryBot.create(:migration_delivery_partner) }
  let(:ecf1_partnership) { FactoryBot.create(:migration_partnership, lead_provider: ecf1_lead_provider, delivery_partner: ecf1_delivery_partner, cohort: ecf1_cohort, school: ecf1_school) }

  let!(:ecf1_induction_programme) { FactoryBot.create(:migration_induction_programme, :provider_led, school_cohort: ecf1_school_cohort, partnership: ecf1_partnership) }

  let!(:ecf1_active_state) do
    FactoryBot.create(
      :migration_participant_profile_state,
      :active,
      participant_profile: ecf1_participant_profile,
      created_at: user_created_at,
      cpd_lead_provider: ecf1_lead_provider.cpd_lead_provider
    )
  end

  let!(:ecf1_induction_record_1) do
    FactoryBot.create(
      :migration_induction_record,
      participant_profile: ecf1_participant_profile,
      induction_programme: ecf1_induction_programme,
      created_at: user_created_at,
      start_date: user_created_at,
      end_date: user_created_at + 1.month,
      induction_status: "changed",
      schedule: ecf1_schedule
    )
  end

  let!(:ecf1_induction_record_2) do
    FactoryBot.create(
      :migration_induction_record,
      participant_profile: ecf1_participant_profile,
      induction_programme: ecf1_induction_programme,
      created_at: ecf1_induction_record_1.end_date,
      start_date: ecf1_induction_record_1.end_date,
      end_date: ecf1_induction_record_1.end_date + 1.month,
      induction_status: "changed",
      schedule: ecf1_schedule
    )
  end

  let!(:ecf1_induction_record_3) do
    FactoryBot.create(
      :migration_induction_record,
      participant_profile: ecf1_participant_profile,
      induction_programme: ecf1_induction_programme,
      created_at: ecf1_induction_record_2.end_date,
      start_date: ecf1_induction_record_2.end_date,
      end_date: ecf1_induction_record_2.end_date + 1.month,
      induction_status: "changed",
      schedule: ecf1_schedule
    )
  end

  let!(:ecf1_induction_record_4) do
    FactoryBot.create(
      :migration_induction_record,
      participant_profile: ecf1_participant_profile,
      induction_programme: ecf1_induction_programme,
      created_at: ecf1_induction_record_3.end_date,
      start_date: ecf1_induction_record_3.end_date,
      end_date: ecf1_induction_record_3.end_date + 1.month,
      induction_status: "changed",
      schedule: ecf1_schedule
    )
  end

  let!(:ecf1_induction_record_5) do
    FactoryBot.create(
      :migration_induction_record,
      participant_profile: ecf1_participant_profile,
      induction_programme: ecf1_induction_programme,
      created_at: ecf1_induction_record_4.end_date,
      start_date: ecf1_induction_record_4.end_date,
      end_date: nil,
      schedule: ecf1_schedule
    )
  end

  let(:ecf1_teacher_profile) { ecf1_participant_profile.teacher_profile }

  # ECF2 data
  let!(:ecf2_gias_school) { FactoryBot.create(:gias_school, :with_school, urn: ecf1_school.urn) }
  let(:ecf2_school) { ecf2_gias_school.school }
  let!(:ecf2_contract_period) { FactoryBot.create(:contract_period, year: ecf1_cohort.start_year) }
  let!(:ecf2_schedule) { FactoryBot.create(:schedule, contract_period: ecf2_contract_period, identifier: ecf1_schedule.schedule_identifier) }
  let!(:ecf2_lead_provider) { FactoryBot.create(:lead_provider, name: ecf1_lead_provider.name, ecf_id: ecf1_lead_provider.id) }
  let!(:ecf2_delivery_partner) { FactoryBot.create(:delivery_partner, name: ecf1_delivery_partner.name, api_id: ecf1_delivery_partner.id) }

  # - first school partnership
  let!(:ecf2_active_lead_provider) { FactoryBot.create(:active_lead_provider, lead_provider: ecf2_lead_provider, contract_period: ecf2_contract_period) }
  let!(:ecf2_lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider: ecf2_active_lead_provider, delivery_partner: ecf2_delivery_partner) }
  let!(:ecf2_school_partnership) { FactoryBot.create(:school_partnership, school: ecf2_school, lead_provider_delivery_partnership: ecf2_lead_provider_delivery_partnership) }

  # Conversion objects
  let(:ecf1_teacher_history) { ECF1TeacherHistory.build(teacher_profile: ecf1_teacher_profile) }
  let(:teacher_history_converter) { TeacherHistoryConverter.new(ecf1_teacher_history:, migration_mode:) }

  before do
    ecf2_teacher_history = teacher_history_converter.convert_to_ecf2!
    ecf2_teacher_history.save_all_mentor_data!
  end

  context "when in latest_induction_records mode (economy)" do
    let(:migration_mode) { :latest_induction_records }

    it "creates the teacher record" do
      expect(teacher).to be_persisted
      expect(teacher.migration_mode).to eq "latest_induction_records"
    end

    it "creates one mentor_at_school_period" do
      expect(teacher.mentor_at_school_periods.count).to eq(1)
    end

    it "creates one training_period on the mentor_at_school_period" do
      expect(teacher.mentor_at_school_periods.first.training_periods.count).to eq(1)
    end

    it "the training_period is ongoing" do
      training_period = teacher.mentor_at_school_periods.first.training_periods.first

      expect(training_period.started_on).to eq(ecf1_induction_record_5.start_date.to_date)
      expect(training_period).to be_ongoing
    end

    it "the mentor_at_school_period is ongoing" do
      mentor_at_school_period = teacher.mentor_at_school_periods.first
      expect(mentor_at_school_period.started_on).to eq(ecf1_induction_record_5.start_date.to_date)
      expect(mentor_at_school_period).to be_ongoing
    end
  end

  context "when in all_induction_records mode (premium)" do
    let(:migration_mode) { :all_induction_records }

    it "creates the teacher record" do
      expect(teacher).to be_persisted
      expect(teacher.migration_mode).to eq "all_induction_records"
    end

    it "creates one mentor_at_school_period" do
      expect(teacher.mentor_at_school_periods.count).to eq(1)
    end

    it "creates one training_period on the mentor_at_school_period" do
      expect(teacher.mentor_at_school_periods.first.training_periods.count).to eq(1)
    end

    it "the training_period is ongoing" do
      training_period = teacher.mentor_at_school_periods.first.training_periods.first

      aggregate_failures do
        expect(training_period.started_on).to eq(ecf1_induction_record_1.start_date.to_date)
        expect(training_period).to be_ongoing
      end
    end

    it "the mentor_at_school_period is ongoing" do
      mentor_at_school_period = teacher.mentor_at_school_periods.first

      aggregate_failures do
        expect(mentor_at_school_period.started_on).to eq(ecf1_induction_record_1.start_date.to_date)
        expect(mentor_at_school_period).to be_ongoing
      end
    end
  end
end
