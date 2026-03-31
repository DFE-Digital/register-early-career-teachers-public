describe "Teacher mentoring at several schools" do
  subject(:teacher) { Teacher.find_by(trn: ecf1_teacher_profile.trn) }

  # Timestamps we care about
  let(:user_created_at) { 3.years.ago.round }
  let(:original_teacher_created_at) { 1.year.ago.round }
  let(:mentor_completion_date) { Date.new(2023, 2, 3) }
  let(:mentor_completion_reason) { "completed_declaration_received" }

  # ECF1 data
  let(:ecf1_participant_profile) { FactoryBot.create(:migration_participant_profile, :mentor, mentor_completion_date:, mentor_completion_reason:) }
  let(:ecf1_induction_programme) { FactoryBot.create(:migration_induction_programme, :provider_led) }
  let(:ecf1_school) { ecf1_induction_programme.school_cohort.school }
  let(:ecf1_induction_record) { FactoryBot.create(:migration_induction_record, induction_programme: ecf1_induction_programme, created_at: 18.hours.ago.round, participant_profile: ecf1_participant_profile) }
  let(:ecf1_teacher_profile) { ecf1_induction_record.participant_profile.teacher_profile }
  let(:ecf1_urn) { ecf1_induction_programme.school_cohort.school.urn.to_i }
  let(:ecf1_school_mentor) { FactoryBot.create(:ecf_migration_school_mentor, participant_profile: ecf1_participant_profile, created_at: ecf1_induction_record.start_date, school: ecf1_school) }
  let(:ecf1_extra_school_mentor) { FactoryBot.create(:ecf_migration_school_mentor, participant_profile: ecf1_participant_profile) }

  # ECF2 data
  let(:ecf2_school) { ecf2_gias_school.school }
  let(:ecf2_extra_school) { ecf2_extra_gias_school.school }
  let(:ecf2_contract_period) { FactoryBot.create(:contract_period, year: ecf1_induction_record.induction_programme.school_cohort.cohort.start_year) }
  let(:ecf2_lead_provider) { FactoryBot.create(:lead_provider, name: ecf1_induction_programme.partnership.lead_provider.name, ecf_id: ecf1_induction_programme.partnership.lead_provider_id) }
  let(:ecf2_delivery_partner) { FactoryBot.create(:delivery_partner, name: ecf1_induction_programme.partnership.delivery_partner.name, api_id: ecf1_induction_programme.partnership.delivery_partner_id) }
  let(:ecf2_active_lead_provider) { FactoryBot.create(:active_lead_provider, lead_provider: ecf2_lead_provider, contract_period: ecf2_contract_period) }
  let(:ecf2_lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider: ecf2_active_lead_provider, delivery_partner: ecf2_delivery_partner) }

  let!(:ecf2_teacher) { FactoryBot.create(:teacher, trn: ecf1_teacher_profile.trn, created_at: original_teacher_created_at, trs_first_name: "Janet", trs_last_name: "Fielding") }
  let!(:ecf2_gias_school) { FactoryBot.create(:gias_school, :with_school, urn: ecf1_urn) }
  let!(:ecf2_extra_gias_school) { FactoryBot.create(:gias_school, :with_school, urn: ecf1_extra_school_mentor.school.urn) }
  let!(:ecf2_schedule) { FactoryBot.create(:schedule, contract_period: ecf2_contract_period, identifier: ecf1_induction_record.schedule.schedule_identifier) }
  let!(:ecf2_school_partnership) { FactoryBot.create(:school_partnership, school: ecf2_school, lead_provider_delivery_partnership: ecf2_lead_provider_delivery_partnership) }

  # Conversion objects
  let(:ecf1_teacher_history) { ECF1TeacherHistory.build(teacher_profile: ecf1_teacher_profile) }
  let(:teacher_history_converter) { TeacherHistoryConverter.new(ecf1_teacher_history:, migration_mode:) }

  before do
    ecf1_teacher_profile.user.update!(created_at: user_created_at)
    ecf1_participant_profile.school_mentors = [ecf1_school_mentor, ecf1_extra_school_mentor]

    ecf2_teacher_history = teacher_history_converter.convert_to_ecf2!
    ecf2_teacher_history.save_all_mentor_data!
  end

  context "when in latest_induction_records mode (economy)" do
    let(:migration_mode) { :latest_induction_records }

    it "creates the teacher record" do
      expect(teacher).to be_persisted
      expect(teacher.migration_mode).to eq "latest_induction_records"
    end

    it "sets the ECF2 teacher's created_at to the ECF1 user's" do
      expect(teacher.created_at).to eql(user_created_at)
    end

    it "sets the ECF2 teacher's mentor completion date and reason" do
      aggregate_failures do
        expect(teacher.mentor_became_ineligible_for_funding_on).to eql(mentor_completion_date)
        expect(teacher.mentor_became_ineligible_for_funding_reason).to eql(mentor_completion_reason)
      end
    end

    it "doesn't overwrite the TRS first and last names" do
      expect(teacher.trs_first_name).to eql("Janet")
      expect(teacher.trs_last_name).to eql("Fielding")
    end

    it "creates mentor_at_school_periods linked to the teacher at the school they are training" do
      mentor_at_school_periods = teacher.mentor_at_school_periods
      mentor_at_school_period = mentor_at_school_periods.first

      aggregate_failures do
        expect(mentor_at_school_periods.count).to be(1)

        expect(mentor_at_school_period.school.urn).to eql(ecf1_urn)
      end
    end

    it "creates a single training_period for the teacher linked to the right schedule and school partnership" do
      training_periods = teacher.mentor_at_school_periods.first.training_periods
      training_period = training_periods.first

      aggregate_failures do
        expect(training_periods.count).to be(1)

        expect(training_period.school_partnership.contract_period.year).to eql(ecf1_induction_programme.partnership.cohort.start_year)
        expect(training_period.school_partnership.lead_provider.name).to eql(ecf1_induction_programme.partnership.lead_provider.name)
        expect(training_period.school_partnership.delivery_partner.name).to eql(ecf1_induction_programme.partnership.delivery_partner.name)

        expect(training_period.schedule.identifier).to eql(ecf1_induction_record.schedule.schedule_identifier)
        expect(training_period.schedule.contract_period_year).to eql(ecf1_induction_record.schedule.cohort.start_year)

        expect(training_period.created_at).to eql(ecf1_induction_record.created_at)
      end
    end
  end

  context "when in all_induction_records mode (premium)" do
    let(:migration_mode) { :all_induction_records }

    it "creates the teacher record" do
      expect(teacher).to be_persisted
      expect(teacher.migration_mode).to eq "all_induction_records"
    end

    it "creates a single mentor_at_school_period linked to the teacher at the right school" do
      mentor_at_school_periods = teacher.mentor_at_school_periods.where(school: ecf2_school)
      mentor_at_school_period = mentor_at_school_periods.first

      aggregate_failures do
        expect(mentor_at_school_periods.count).to be(1)

        expect(mentor_at_school_period.school.urn).to eql(ecf1_urn)
      end
    end

    it "creates an extra mentor_at_school_period linked to the teacher and the extra school_mentor school" do
      mentor_at_school_periods = teacher.mentor_at_school_periods.where.not(school: ecf2_school)
      mentor_at_school_period = mentor_at_school_periods.first

      aggregate_failures do
        expect(mentor_at_school_periods.count).to be(1)
        expect(mentor_at_school_period.school).to eql(ecf2_extra_school)
      end
    end

    it "creates a single training_period for the teacher linked to the right schedule and school partnership" do
      training_periods = teacher.mentor_at_school_periods.first.training_periods
      training_period = training_periods.first

      aggregate_failures do
        expect(training_periods.count).to be(1)

        expect(training_period.school_partnership.contract_period.year).to eql(ecf1_induction_programme.partnership.cohort.start_year)
        expect(training_period.school_partnership.lead_provider.name).to eql(ecf1_induction_programme.partnership.lead_provider.name)
        expect(training_period.school_partnership.delivery_partner.name).to eql(ecf1_induction_programme.partnership.delivery_partner.name)

        expect(training_period.schedule.identifier).to eql(ecf1_induction_record.schedule.schedule_identifier)
        expect(training_period.schedule.contract_period_year).to eql(ecf1_induction_record.schedule.cohort.start_year)

        expect(training_period.created_at).to eql(ecf1_induction_record.created_at)
      end
    end
  end
end
