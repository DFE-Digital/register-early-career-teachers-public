describe "Ensuring mentorship periods are at least one day long" do
  subject(:teacher) { Teacher.find_by(trn:) }

  # ECF1 data

  let(:ecf1_cohort) { FactoryBot.create(:migration_cohort, start_year: 2022) }
  let(:ecf1_schedule) { FactoryBot.create(:migration_schedule, schedule_identifier: "ecf-standard-september", name: "ECF Standard September", cohort: ecf1_cohort) }

  let(:ecf1_participant_profile) { FactoryBot.create(:migration_participant_profile, :ect, schedule: ecf1_schedule) }
  let(:ecf1_teacher_profile) { ecf1_participant_profile.teacher_profile }

  let(:ecf1_school) { FactoryBot.create(:ecf_migration_school) }

  let!(:ecf1_delivery_partner_1) { FactoryBot.create(:migration_delivery_partner) }

  let(:ecf1_cpd_lp_ambition) { FactoryBot.create(:migration_cpd_lead_provider, name: "Ambition Institute", id: "22727fdc-816a-4a3c-9675-030e724bbf89") }

  let!(:ecf1_ambition) { FactoryBot.create(:migration_lead_provider, id: "c3bc3cee-a636-42d6-8324-c033a6c38d31", name: "Ambition Institute", cpd_lead_provider: ecf1_cpd_lp_ambition) }

  let(:ecf1_school_partnership) { FactoryBot.create(:migration_partnership, school: ecf1_school, lead_provider: ecf1_ambition, cohort: ecf1_cohort, delivery_partner: ecf1_delivery_partner_1) }

  let(:ecf1_cohort_1) { FactoryBot.create(:migration_school_cohort, school: ecf1_school, cohort: ecf1_cohort) }

  let(:ecf1_induction_programme) do
    FactoryBot.create(:migration_induction_programme, school_cohort: ecf1_cohort_1, training_programme: :full_induction_programme, partnership: ecf1_school_partnership)
  end

  let!(:ecf1_induction_record_1) do
    #  #<Migration::InductionRecord:0x00007fa9e193ec60
    #  id: "86a5395d-3bf4-4fb8-b5e5-f642337b1fa0",
    #  induction_programme_id: "157d14b9-064d-42ea-b6c8-b6a7e1a18f51",
    #  participant_profile_id: "f1a3f761-db41-46bc-b354-48bcea6a9cd0",
    #  schedule_id: "c4d6a996-b0fe-495e-be2e-11cb064253c2",
    #  start_date: "2022-09-01 01:00:00.000000000 +0100",
    #  end_date: "2023-04-21 09:34:43.664240000 +0100",
    #  created_at: "2022-06-16 10:27:51.176977000 +0100",
    #  updated_at: "2023-04-21 09:34:43.667237000 +0100",
    #  training_status: "active",
    #  preferred_identity_id: "955cdf1e-a436-4214-a3f0-d104fe846192",
    #  induction_status: "changed",
    #  mentor_profile_id: "70b6ae18-74f8-42c0-b405-7a8325800515",
    #  school_transfer: false,
    #  appropriate_body_id: nil>,
    FactoryBot.create(
      :migration_induction_record,
      training_status: "active",
      start_date: Date.new(2022, 9, 1),
      end_date: Date.new(2023, 4, 21),
      induction_programme: ecf1_induction_programme,
      participant_profile: ecf1_participant_profile,
      schedule: ecf1_schedule
    )
  end

  let!(:ecf1_induction_record_2) do
    # #<Migration::InductionRecord:0x00007fa9e17575a0
    #  id: "412a1029-0fa6-4421-9184-d73759bc3984",
    #  induction_programme_id: "157d14b9-064d-42ea-b6c8-b6a7e1a18f51",
    #  participant_profile_id: "f1a3f761-db41-46bc-b354-48bcea6a9cd0",
    #  schedule_id: "c4d6a996-b0fe-495e-be2e-11cb064253c2",
    #  start_date: "2023-04-21 09:34:43.664240000 +0100",
    #  end_date: "2024-06-12 15:06:31.809946000 +0100",
    #  created_at: "2023-04-21 09:34:43.687445000 +0100",
    #  updated_at: "2024-06-12 15:06:31.812534000 +0100",
    #  training_status: "active",
    #  preferred_identity_id: "955cdf1e-a436-4214-a3f0-d104fe846192",
    #  induction_status: "changed",
    #  mentor_profile_id: "5dead953-4bf7-4acb-b0ab-ad7cd84f1f80",
    #  school_transfer: true,
    #  appropriate_body_id: nil>,
    FactoryBot.create(
      :migration_induction_record,
      training_status: "active",
      start_date: Date.new(2023, 4, 21),
      end_date: Date.new(2024, 6, 12),
      induction_programme: ecf1_induction_programme,
      participant_profile: ecf1_participant_profile,
      schedule: ecf1_schedule,
      mentor_profile_id: "5dead953-4bf7-4acb-b0ab-ad7cd84f1f80"
    )
  end

  let!(:ecf1_induction_record_3) do
    # #<Migration::InductionRecord:0x00007fa9e1757460
    #  id: "fb3a73f1-6734-408b-bffd-1dd1692dd616",
    #  induction_programme_id: "157d14b9-064d-42ea-b6c8-b6a7e1a18f51",
    #  participant_profile_id: "f1a3f761-db41-46bc-b354-48bcea6a9cd0",
    #  schedule_id: "c4d6a996-b0fe-495e-be2e-11cb064253c2",
    #  start_date: "2024-06-12 15:06:31.809946000 +0100",
    #  end_date: "2023-07-21 01:00:00.000000000 +0100",
    #  created_at: "2024-06-12 15:06:31.832800000 +0100",
    #  updated_at: "2024-06-12 15:06:31.832800000 +0100",
    #  training_status: "withdrawn",
    #  preferred_identity_id: "955cdf1e-a436-4214-a3f0-d104fe846192",
    #  induction_status: "leaving",
    #  mentor_profile_id: "5dead953-4bf7-4acb-b0ab-ad7cd84f1f80",
    #  school_transfer: false,
    #  appropriate_body_id: nil>]
    FactoryBot.create(
      :migration_induction_record,
      training_status: "withdrawn",
      start_date: Date.new(2024, 6, 12),
      end_date: Date.new(2023, 7, 21),
      induction_programme: ecf1_induction_programme,
      participant_profile: ecf1_participant_profile,
      schedule: ecf1_schedule,
      mentor_profile_id: "5dead953-4bf7-4acb-b0ab-ad7cd84f1f80"
    )
  end

  #  [#<Migration::ParticipantProfileState:0x00007fa9e20b4760
  #  id: "50ae7116-8380-4819-afcd-554a7809a15e",
  #  participant_profile_id: "f1a3f761-db41-46bc-b354-48bcea6a9cd0",
  #  state: "active",
  #  reason: nil,
  #  created_at: "2022-06-16 10:27:51.171676000 +0100",
  #  updated_at: "2022-06-16 10:27:51.171676000 +0100",
  #  cpd_lead_provider_id: nil>,
  let!(:ecf1_state_1) { FactoryBot.create(:migration_participant_profile_state, :active, created_at: Time.zone.local(2022, 6, 16), cpd_lead_provider: nil, participant_profile: ecf1_participant_profile) }

  # #<Migration::ParticipantProfileState:0x00007fa9f26f5650
  #  id: "64de69b6-1395-4553-bc08-7b9c1fe95ca7",
  #  participant_profile_id: "f1a3f761-db41-46bc-b354-48bcea6a9cd0",
  #  state: "withdrawn",
  #  reason: "moved-school",
  #  created_at: "2024-06-12 15:06:31.796879000 +0100",
  #  updated_at: "2024-06-12 15:06:31.796879000 +0100",
  #  cpd_lead_provider_id: "22727fdc-816a-4a3c-9675-030e724bbf89">]
  let!(:ecf1_state_2) { FactoryBot.create(:migration_participant_profile_state, :withdrawn, reason: "moved-school", created_at: Time.zone.local(2024, 6, 12), cpd_lead_provider: ecf1_cpd_lp_ambition, participant_profile: ecf1_participant_profile) }

  # ECF2 data

  let!(:ecf2_teacher) { FactoryBot.create(:teacher, trn: ecf1_teacher_profile.trn) }

  let!(:ecf2_school) { FactoryBot.create(:school, urn: ecf1_school.urn, api_id: ecf1_school.id) }

  let(:ecf2_ambition) { FactoryBot.create(:lead_provider, name: "Ambition Institute", ecf_id: ecf1_ambition.id) }

  let(:ecf2_contract_period) { FactoryBot.create(:contract_period, year: 2022) }

  let!(:schedule) { FactoryBot.create(:schedule, identifier: "ecf-standard-september", contract_period: ecf2_contract_period) }

  let(:ecf2_active_lead_provider_ambition) { FactoryBot.create(:active_lead_provider, lead_provider: ecf2_ambition, contract_period: ecf2_contract_period) }

  let(:ecf2_delivery_partner_1) { FactoryBot.create(:delivery_partner, api_id: ecf1_delivery_partner_1.id) }

  let(:ecf2_lpdp_ambition) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider: ecf2_active_lead_provider_ambition, delivery_partner: ecf2_delivery_partner_1) }

  let!(:school_partnership_1) { FactoryBot.create(:school_partnership, lead_provider_delivery_partnership: ecf2_lpdp_ambition, school: ecf2_school) }

  # Mentor data

  let(:mentor) { FactoryBot.create(:teacher, api_mentor_training_record_id: "5dead953-4bf7-4acb-b0ab-ad7cd84f1f80") }
  let!(:mentor_at_school_period_1) { FactoryBot.create(:mentor_at_school_period, teacher: mentor, school: ecf2_school, started_on: Date.new(2022, 6, 1), finished_on: mentor_finished_on) }
  let!(:mentor_at_school_period_2) { FactoryBot.create(:mentor_at_school_period, teacher: mentor, school: ecf2_school, started_on: Date.new(2024, 6, 12), finished_on: Date.new(2024, 6, 13)) }

  # Conversion objects

  let(:ecf1_teacher_history) { ECF1TeacherHistory.build(teacher_profile: ecf1_teacher_profile) }
  let(:teacher_history_converter) { TeacherHistoryConverter.new(ecf1_teacher_history:, migration_mode:) }

  before do
    ecf2_teacher_history = teacher_history_converter.convert_to_ecf2!
    ecf2_teacher_history.save_all_ect_data!
  end

  context "when in economy mode" do
    subject(:teacher) { Teacher.find_by(trn: ecf1_teacher_profile.trn) }

    let(:migration_mode) { :latest_induction_records }
    let(:mentorship_periods) { teacher.ect_at_school_periods[0].mentorship_periods }

    context "when the mentor finishes on the same day as the ECT starts" do
      let(:mentor_finished_on) { Date.new(2023, 7, 21) }

      it "successfully creates the teacher with no mentorship periods" do
        expect(mentorship_periods).to be_empty
      end
    end

    context "when the mentor finishes the day after as the ECT starts" do
      let(:mentor_finished_on) { Date.new(2023, 7, 22) }

      it "successfully creates the teacher with a mentorship period" do
        expect(mentorship_periods.count).to be(1)
      end
    end
  end
end
