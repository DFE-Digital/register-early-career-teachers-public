describe "ECT with multiple withdrawals" do
  subject(:teacher) { Teacher.find_by(trn:) }

  around do |example|
    travel_to(Date.new(2026, 4, 12)) { example.run }
  end

  # ECF1 data

  let(:ecf1_cohort) { FactoryBot.create(:migration_cohort, start_year: 2024) }
  let(:ecf1_schedule) { FactoryBot.create(:migration_schedule, schedule_identifier: "ecf-standard-september", name: "ECF Standard September", cohort: ecf1_cohort) }

  let(:ecf1_participant_profile) { FactoryBot.create(:migration_participant_profile, :ect, schedule: ecf1_schedule) }
  let(:ecf1_teacher_profile) { ecf1_participant_profile.teacher_profile }

  let(:ecf1_school_1) { FactoryBot.create(:ecf_migration_school) } # meadow park
  let(:ecf1_school_2) { FactoryBot.create(:ecf_migration_school) } # fullhusrt community college
  let(:ecf1_school_3) { FactoryBot.create(:ecf_migration_school) } # crown hills

  let!(:ecf1_delivery_partner_1) { FactoryBot.create(:migration_delivery_partner) }
  let!(:ecf1_delivery_partner_2) { FactoryBot.create(:migration_delivery_partner) }
  let!(:ecf1_delivery_partner_3) { FactoryBot.create(:migration_delivery_partner) }

  let(:ecf1_cpd_lp_ucl) { FactoryBot.create(:migration_cpd_lead_provider, name: "UCL Institute of Education", id: "fb9c56b2-252b-41fe-b6b2-ebf208999df9") }
  let(:ecf1_cpd_lp_tf) { FactoryBot.create(:migration_cpd_lead_provider, name: "UCL Institute of Education", id: "bd152c5a-5ef4-4584-9c63-c32877dbba07") }

  let!(:ecf1_ucl) { FactoryBot.create(:migration_lead_provider, id: "3d7d8c90-a5a3-4838-84b2-563092bf87ee", name: "UCL Institute of Education", cpd_lead_provider: ecf1_cpd_lp_ucl) }
  let!(:ecf1_tf) { FactoryBot.create(:migration_lead_provider, id: "99317668-2942-4292-a895-fdb075af067b", name: "Teach First", cpd_lead_provider: ecf1_cpd_lp_tf) }

  let(:ecf1_school_partnership_1) { FactoryBot.create(:migration_partnership, school: ecf1_school_1, lead_provider: ecf1_ucl, cohort: ecf1_cohort, delivery_partner: ecf1_delivery_partner_1) }
  let(:ecf1_school_partnership_2) { FactoryBot.create(:migration_partnership, school: ecf1_school_2, lead_provider: ecf1_tf, cohort: ecf1_cohort, delivery_partner: ecf1_delivery_partner_2) }
  let(:ecf1_school_partnership_3) { FactoryBot.create(:migration_partnership, school: ecf1_school_3, lead_provider: ecf1_tf, cohort: ecf1_cohort, delivery_partner: ecf1_delivery_partner_3) }

  let(:ecf1_cohort_1) { FactoryBot.create(:migration_school_cohort, school: ecf1_school_1, cohort: ecf1_cohort) }
  let(:ecf1_cohort_2) { FactoryBot.create(:migration_school_cohort, school: ecf1_school_2, cohort: ecf1_cohort) }
  let(:ecf1_cohort_3) { FactoryBot.create(:migration_school_cohort, school: ecf1_school_3, cohort: ecf1_cohort) }

  let(:ecf1_induction_programme_1) do
    FactoryBot.create(:migration_induction_programme, school_cohort: ecf1_cohort_1, training_programme: :full_induction_programme, partnership: ecf1_school_partnership_1)
  end

  let(:ecf1_induction_programme_2) do
    FactoryBot.create(:migration_induction_programme, school_cohort: ecf1_cohort_2, training_programme: :full_induction_programme, partnership: ecf1_school_partnership_2)
  end

  let(:ecf1_induction_programme_3) do
    FactoryBot.create(:migration_induction_programme, school_cohort: ecf1_cohort_3, training_programme: :full_induction_programme, partnership: ecf1_school_partnership_3)
  end

  let!(:ecf1_induction_record_1) do
    # [{start_date: Sat, 01 Jun 2024,
    #   end_date: Wed, 17 Jul 2024,
    #   training_status: "active",
    #   induction_programme: "full_induction_programme",
    #   lead_provider: #<data Types::LeadProviderInfo ecf1_id="3d7d8c90-a5a3-4838-84b2-563092bf87ee", name="UCL Institute of Education">,
    #   school: #<struct Struct::SchoolData urn="148429", name="Nice Park School", school_type_name="Academy converter">,
    #   cohort: 2024,
    #   schedule: #<data Types::ScheduleInfo schedule_id="a033708c-7aa4-4410-afbf-0e0f3f2f7466", identifier="ecf-standard-september", name="ECF Standard September", cohort_year=2024>},
    FactoryBot.create(
      :migration_induction_record,
      training_status: "active",
      start_date: Date.new(2024, 6, 1),
      end_date: Date.new(2024, 7, 17),
      induction_programme: ecf1_induction_programme_1,
      participant_profile: ecf1_participant_profile,
      schedule: ecf1_schedule
    )
  end

  let!(:ecf1_induction_record_2) do
    #  {start_date: Wed, 17 Jul 2024,
    #   end_date: Wed, 26 Feb 2025,
    #   training_status: "active",
    #   induction_programme: "full_induction_programme",
    #   lead_provider: #<data Types::LeadProviderInfo ecf1_id="3d7d8c90-a5a3-4838-84b2-563092bf87ee", name="UCL Institute of Education">,
    #   school: #<struct Struct::SchoolData urn="148429", name="Nice Park School", school_type_name="Academy converter">,
    #   cohort: 2024,
    #   schedule: #<data Types::ScheduleInfo schedule_id="a033708c-7aa4-4410-afbf-0e0f3f2f7466", identifier="ecf-standard-september", name="ECF Standard September", cohort_year=2024>},
    FactoryBot.create(
      :migration_induction_record,
      training_status: "active",
      start_date: Date.new(2024, 7, 17),
      end_date: Date.new(2025, 2, 26),
      induction_programme: ecf1_induction_programme_1,
      participant_profile: ecf1_participant_profile,
      schedule: ecf1_schedule
    )
  end

  let!(:ecf1_induction_record_3) do
    #  {start_date: Wed, 26 Feb 2025,
    #   end_date: Thu, 25 Sep 2025,
    #   training_status: "active",
    #   induction_programme: "full_induction_programme",
    #   lead_provider: #<data Types::LeadProviderInfo ecf1_id="3d7d8c90-a5a3-4838-84b2-563092bf87ee", name="UCL Institute of Education">,
    #   school: #<struct Struct::SchoolData urn="148429", name="Nice Park School", school_type_name="Academy converter">,
    #   cohort: 2024,
    #   schedule: #<data Types::ScheduleInfo schedule_id="a033708c-7aa4-4410-afbf-0e0f3f2f7466", identifier="ecf-standard-september", name="ECF Standard September", cohort_year=2024>},
    FactoryBot.create(
      :migration_induction_record,
      training_status: "active",
      start_date: Date.new(2025, 2, 26),
      end_date: Date.new(2025, 9, 25),
      induction_programme: ecf1_induction_programme_1,
      participant_profile: ecf1_participant_profile,
      schedule: ecf1_schedule
    )
  end

  let!(:ecf1_induction_record_4) do
    #  {start_date: Fri, 22 Aug 2025,
    #   end_date: Tue, 26 Aug 2025,
    #   training_status: "active",
    #   induction_programme: "full_induction_programme",
    #   lead_provider: #<data Types::LeadProviderInfo ecf1_id="99317668-2942-4292-a895-fdb075af067b", name="Teach First">,
    #   school: #<struct Struct::SchoolData urn="120298", name="Some Community College", school_type_name="Foundation school">,
    #   cohort: 2024,
    #   schedule: #<data Types::ScheduleInfo schedule_id="a033708c-7aa4-4410-afbf-0e0f3f2f7466", identifier="ecf-standard-september", name="ECF Standard September", cohort_year=2024>},
    FactoryBot.create(
      :migration_induction_record,
      training_status: "active",
      start_date: Date.new(2025, 8, 22),
      end_date: Date.new(2025, 8, 26),
      induction_programme: ecf1_induction_programme_2,
      participant_profile: ecf1_participant_profile,
      schedule: ecf1_schedule
    )
  end

  let!(:ecf1_induction_record_5) do
    #  {start_date: Tue, 26 Aug 2025,
    #   end_date: Fri, 26 Sep 2025,
    #   training_status: "active",
    #   induction_programme: "full_induction_programme",
    #   lead_provider: #<data Types::LeadProviderInfo ecf1_id="99317668-2942-4292-a895-fdb075af067b", name="Teach First">,
    #   school: #<struct Struct::SchoolData urn="120298", name="Some Community College", school_type_name="Foundation school">,
    #   cohort: 2024,
    #   schedule: #<data Types::ScheduleInfo schedule_id="a033708c-7aa4-4410-afbf-0e0f3f2f7466", identifier="ecf-standard-september", name="ECF Standard September", cohort_year=2024>},
    FactoryBot.create(
      :migration_induction_record,
      training_status: "active",
      start_date: Date.new(2025, 8, 26),
      end_date: Date.new(2025, 9, 26),
      induction_programme: ecf1_induction_programme_2,
      participant_profile: ecf1_participant_profile,
      schedule: ecf1_schedule
    )
  end

  let!(:ecf1_induction_record_6) do
    #  {start_date: Fri, 22 Aug 2025,
    #   end_date: Sat, 23 Aug 2025,
    #   training_status: "withdrawn",
    #   induction_programme: "full_induction_programme",
    #   lead_provider: #<data Types::LeadProviderInfo ecf1_id="3d7d8c90-a5a3-4838-84b2-563092bf87ee", name="UCL Institute of Education">,
    #   school: #<struct Struct::SchoolData urn="148429", name="Nice Park School", school_type_name="Academy converter">,
    #   cohort: 2024,
    #   schedule: #<data Types::ScheduleInfo schedule_id="a033708c-7aa4-4410-afbf-0e0f3f2f7466", identifier="ecf-standard-september", name="ECF Standard September", cohort_year=2024>},
    FactoryBot.create(
      :migration_induction_record,
      training_status: "withdrawn",
      start_date: Date.new(2025, 8, 22),
      end_date: Date.new(2025, 8, 23),
      induction_programme: ecf1_induction_programme_1,
      participant_profile: ecf1_participant_profile,
      schedule: ecf1_schedule
    )
  end

  let!(:ecf1_induction_record_7) do
    #  {start_date: Fri, 26 Sep 2025,
    #   end_date: Mon, 13 Apr 2026,
    #   training_status: "withdrawn",
    #   induction_programme: "full_induction_programme",
    #   lead_provider: #<data Types::LeadProviderInfo ecf1_id="99317668-2942-4292-a895-fdb075af067b", name="Teach First">,
    #   school: #<struct Struct::SchoolData urn="120298", name="Some Community College", school_type_name="Foundation school">,
    #   cohort: 2024,
    #   schedule: #<data Types::ScheduleInfo schedule_id="a033708c-7aa4-4410-afbf-0e0f3f2f7466", identifier="ecf-standard-september", name="ECF Standard September", cohort_year=2024>},
    FactoryBot.create(
      :migration_induction_record,
      training_status: "withdrawn",
      start_date: Date.new(2025, 9, 26),
      end_date: Date.new(2026, 4, 13),
      induction_programme: ecf1_induction_programme_2,
      participant_profile: ecf1_participant_profile,
      schedule: ecf1_schedule
    )
  end

  # NOTE: this one should be prewashed away
  let!(:ecf1_induction_record_8) do
    #  {start_date: Mon, 13 Apr 2026,
    #   end_date: nil,
    #   training_status: "withdrawn",
    #   induction_programme: "full_induction_programme",
    #   lead_provider: #<data Types::LeadProviderInfo ecf1_id="99317668-2942-4292-a895-fdb075af067b", name="Teach First">,
    #   school: #<struct Struct::SchoolData urn="120277", name="Crown Hills Community College", school_type_name="Community school">,
    #   cohort: 2024,
    #   schedule: #<data Types::ScheduleInfo schedule_id="a033708c-7aa4-4410-afbf-0e0f3f2f7466", identifier="ecf-standard-september", name="ECF Standard September", cohort_year=2024>}]
    FactoryBot.create(
      :migration_induction_record,
      training_status: "withdrawn",
      start_date: Date.new(2026, 4, 13),
      end_date: nil,
      induction_programme: ecf1_induction_programme_3,
      participant_profile: ecf1_participant_profile,
      schedule: ecf1_schedule
    )
  end

  # [<struct ECF1TeacherHistory::ProfileState state="active", reason=nil, created_at=2024-07-17 16:11:55.036787000 BST +01:00, cpd_lead_provider_id="fb9c56b2-252b-41fe-b6b2-ebf208999df9">,
  let!(:ecf1_state_1) { FactoryBot.create(:migration_participant_profile_state, :active, created_at: Time.zone.local(2024, 7, 17), cpd_lead_provider: ecf1_cpd_lp_ucl, participant_profile: ecf1_participant_profile) }

  # <struct ECF1TeacherHistory::ProfileState state="active", reason=nil, created_at=2025-07-10 17:28:40.195922000 BST +01:00, cpd_lead_provider_id="bd152c5a-5ef4-4584-9c63-c32877dbba07">,
  let!(:ecf1_state_2) { FactoryBot.create(:migration_participant_profile_state, :active, created_at: Time.zone.local(2024, 7, 10), cpd_lead_provider: ecf1_cpd_lp_tf, participant_profile: ecf1_participant_profile) }

  # <struct ECF1TeacherHistory::ProfileState state="withdrawn", reason="moved-school", created_at=2025-09-25 11:14:32.359475000 BST +01:00, cpd_lead_provider_id="fb9c56b2-252b-41fe-b6b2-ebf208999df9">,
  let!(:ecf1_state_3) { FactoryBot.create(:migration_participant_profile_state, :withdrawn, reason: "moved-school", created_at: Time.zone.local(2024, 9, 25), cpd_lead_provider: ecf1_cpd_lp_ucl, participant_profile: ecf1_participant_profile) }

  # <struct ECF1TeacherHistory::ProfileState state="withdrawn", reason="other", created_at=2025-09-26 03:00:04.120476000 BST +01:00, cpd_lead_provider_id="bd152c5a-5ef4-4584-9c63-c32877dbba07">,
  let!(:ecf1_state_4) { FactoryBot.create(:migration_participant_profile_state, :withdrawn, reason: "other", created_at: Time.zone.local(2024, 9, 26), cpd_lead_provider: ecf1_cpd_lp_tf, participant_profile: ecf1_participant_profile) }

  # <struct ECF1TeacherHistory::ProfileState state="active", reason=nil, created_at=2026-03-10 13:25:46.016441000 GMT +00:00, cpd_lead_provider_id="bd152c5a-5ef4-4584-9c63-c32877dbba07">,
  let!(:ecf1_state_5) { FactoryBot.create(:migration_participant_profile_state, :active, created_at: Time.zone.local(2026, 3, 10), cpd_lead_provider: ecf1_cpd_lp_tf, participant_profile: ecf1_participant_profile) }

  # <struct ECF1TeacherHistory::ProfileState state="withdrawn", reason="other", created_at=2026-03-23 15:12:47.625306000 GMT +00:00, cpd_lead_provider_id="bd152c5a-5ef4-4584-9c63-c32877dbba07">]
  let!(:ecf1_state_6) { FactoryBot.create(:migration_participant_profile_state, :withdrawn, reason: "other", created_at: Time.zone.local(2026, 3, 23), cpd_lead_provider: ecf1_cpd_lp_tf, participant_profile: ecf1_participant_profile) }

  # ECF2 data

  let!(:ecf2_school_1) { FactoryBot.create(:school, urn: ecf1_school_1.urn, api_id: ecf1_school_1.id) } # meadow park
  let!(:ecf2_school_2) { FactoryBot.create(:school, urn: ecf1_school_2.urn, api_id: ecf1_school_2.id) } # fullhusrt community college
  let!(:ecf2_school_3) { FactoryBot.create(:school, urn: ecf1_school_3.urn, api_id: ecf1_school_3.id) } # crown hills

  let(:ecf2_ucl) { FactoryBot.create(:lead_provider, name: "UCL Institute of Education", ecf_id: ecf1_ucl.id) }
  let(:ecf2_tf) { FactoryBot.create(:lead_provider, name: "Teach First", ecf_id: ecf1_tf.id) }

  let(:ecf2_contract_period) { FactoryBot.create(:contract_period, year: 2024) }

  let!(:schedule) { FactoryBot.create(:schedule, identifier: "ecf-standard-september", contract_period: ecf2_contract_period) }

  let(:ecf2_active_lead_provider_ucl) { FactoryBot.create(:active_lead_provider, lead_provider: ecf2_ucl, contract_period: ecf2_contract_period) }
  let(:ecf2_active_lead_provider_tf) { FactoryBot.create(:active_lead_provider, lead_provider: ecf2_tf, contract_period: ecf2_contract_period) }

  let(:ecf2_delivery_partner_1) { FactoryBot.create(:delivery_partner, api_id: ecf1_delivery_partner_1.id) }
  let(:ecf2_delivery_partner_2) { FactoryBot.create(:delivery_partner, api_id: ecf1_delivery_partner_2.id) }
  # let(:ecf2_delivery_partner_3) { FactoryBot.create(:delivery_partner, api_id: ecf1_delivery_partner_3.id) }

  let(:ecf2_lpdp_ucl) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider: ecf2_active_lead_provider_ucl, delivery_partner: ecf2_delivery_partner_1) }
  let(:ecf2_lpdp_tf_1) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider: ecf2_active_lead_provider_tf, delivery_partner: ecf2_delivery_partner_2) }
  # let(:ecf2_lpdp_tf_2) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider: ecf2_active_lead_provider_tf, delivery_partner: ecf2_delivery_partner_3) }

  let!(:school_partnership_1) { FactoryBot.create(:school_partnership, lead_provider_delivery_partnership: ecf2_lpdp_ucl, school: ecf2_school_1) }
  let!(:school_partnership_2) { FactoryBot.create(:school_partnership, lead_provider_delivery_partnership: ecf2_lpdp_tf_1, school: ecf2_school_2) }
  # let!(:school_partnership_3) { FactoryBot.create(:school_partnership, lead_provider_delivery_partnership: ecf2_lpdp_tf_2, school: ecf2_school_3) }

  # Conversion objects

  let(:ecf1_teacher_history) { ECF1TeacherHistory.build(teacher_profile: ecf1_teacher_profile) }
  let(:teacher_history_converter) { TeacherHistoryConverter.new(ecf1_teacher_history:, migration_mode:) }

  before do
    ecf2_teacher_history = teacher_history_converter.convert_to_ecf2!
    ecf2_teacher_history.save_all_ect_data!
  end

  context "when in economy mode" do
    let(:migration_mode) { :latest_induction_records }

    it "ignores the withdrawn future induction record" do
      teacher = Teacher.find_by(trn: ecf1_teacher_profile.trn)

      expect(teacher).to be_present
    end

    it "builds the right number of training periods" do
      teacher = Teacher.find_by(trn: ecf1_teacher_profile.trn)

      expect(teacher.ect_at_school_periods.flat_map(&:training_periods).size).to be(2)
    end
  end
end
