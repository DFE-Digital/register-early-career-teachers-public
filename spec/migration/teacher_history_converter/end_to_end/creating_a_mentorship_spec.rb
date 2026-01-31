describe "Creating a membership (end to end)" do
  subject(:teacher) { Teacher.find_by(trn: ecf1_teacher_profile.trn) }

  # Mentorship data
  let(:mentor_profile_id) { SecureRandom.uuid }
  let(:ect_start_date) { 1.month.ago.to_date }
  let(:mentor_start_date) { 2.months.ago.to_date }

  # ECF1 data
  let(:ecf1_induction_programme) { FactoryBot.create(:migration_induction_programme, :provider_led) }
  let(:ecf1_induction_record) { FactoryBot.create(:migration_induction_record, induction_programme: ecf1_induction_programme, created_at: 18.hours.ago.round, mentor_profile_id:, start_date: ect_start_date) }
  let(:ecf1_teacher_profile) { ecf1_induction_record.participant_profile.teacher_profile }
  let(:ecf1_urn) { ecf1_induction_programme.school_cohort.school.urn.to_i }

  # ECF2 data
  let(:ecf2_school) { ecf2_gias_school.school }
  let(:ecf2_contract_period) { FactoryBot.create(:contract_period, year: ecf1_induction_record.induction_programme.school_cohort.cohort.start_year) }
  let(:ecf2_lead_provider) { FactoryBot.create(:lead_provider, name: ecf1_induction_programme.partnership.lead_provider.name, ecf_id: ecf1_induction_programme.partnership.lead_provider_id) }
  let(:ecf2_delivery_partner) { FactoryBot.create(:delivery_partner, name: ecf1_induction_programme.partnership.delivery_partner.name, api_id: ecf1_induction_programme.partnership.delivery_partner_id) }
  let(:ecf2_active_lead_provider) { FactoryBot.create(:active_lead_provider, lead_provider: ecf2_lead_provider, contract_period: ecf2_contract_period) }
  let(:ecf2_lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider: ecf2_active_lead_provider, delivery_partner: ecf2_delivery_partner) }

  let!(:ecf2_gias_school) { FactoryBot.create(:gias_school, :with_school, urn: ecf1_urn) }
  let!(:ecf2_schedule) { FactoryBot.create(:schedule, contract_period: ecf2_contract_period, identifier: ecf1_induction_record.schedule.schedule_identifier) }
  let!(:ecf2_school_partnership) { FactoryBot.create(:school_partnership, school: ecf2_school, lead_provider_delivery_partnership: ecf2_lead_provider_delivery_partnership) }

  # Mentor data
  let(:mentor_teacher_record) { FactoryBot.create(:teacher, api_mentor_training_record_id: mentor_profile_id) }
  let!(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, :ongoing, started_on: mentor_start_date, teacher: mentor_teacher_record, school: ecf2_school) }

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
    end

    it "creates a single ect_at_school_period linked to the teacher at the right school" do
      ect_at_school_periods = teacher.ect_at_school_periods
      ect_at_school_period = ect_at_school_periods.first

      aggregate_failures do
        expect(ect_at_school_periods.count).to be(1)

        expect(ect_at_school_period.school.urn).to eql(ecf1_urn)
      end
    end

    it "creates a single mentorship_period for the teacher linked to the matching mentor" do
      expect(MentorshipPeriod.count).to be(1)

      mentorship_period = MentorshipPeriod.first

      aggregate_failures do
        expect(mentorship_period.started_on).to eql(ect_start_date)
        expect(mentorship_period.finished_on).to be_nil
        expect(mentorship_period.mentor.teacher).to eql(mentor_teacher_record)
        expect(mentorship_period.mentee.teacher.trn).to eql(ecf1_teacher_profile.trn)
      end
    end
  end

  context "when in all_induction_records mode (premium)", skip: "re-enable once we've implemented premium mode" do
    let(:migration_mode) { :all_induction_records }

    it "creates the teacher record" do
      expect(teacher).to be_persisted
    end
  end
end
