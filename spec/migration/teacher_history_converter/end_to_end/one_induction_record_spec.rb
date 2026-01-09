describe "One induction record (end to end)" do
  subject(:teacher) { Teacher.find_by(trn: ecf1_teacher_profile.trn) }

  # ECF1 data
  let(:ecf1_induction_programme) { FactoryBot.create(:migration_induction_programme, :provider_led) }
  let(:ecf1_induction_record) { FactoryBot.create(:migration_induction_record, induction_programme: ecf1_induction_programme, created_at: 18.hours.ago.round) }
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

    it "creates a single training_period for the teacher linked to the right schedule and school partnership" do
      training_periods = teacher.ect_at_school_periods.first.training_periods
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

  context "when in all_induction_records mode (premium)", pending: "re-enable once we've implemented premium mode" do
    let(:migration_mode) { :all_induction_records }

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

    it "creates a single training_period for the teacher linked to the right schedule and school partnership" do
      training_periods = teacher.ect_at_school_periods.first.training_periods
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
