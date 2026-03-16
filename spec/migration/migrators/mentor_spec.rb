RSpec.describe Migrators::Mentor do
  describe ".teachers" do
    it "only includes teacher profiles with Mentor participant profiles" do
      teacher_profile_with_ect = FactoryBot.create(:migration_teacher_profile)
      ect = FactoryBot.create(:migration_participant_profile, :ect, teacher_profile: teacher_profile_with_ect, user: teacher_profile_with_ect.user)
      FactoryBot.create(:migration_induction_record, participant_profile: ect)

      teacher_profile_with_mentor = FactoryBot.create(:migration_teacher_profile)
      mentor = FactoryBot.create(:migration_participant_profile, :mentor, teacher_profile: teacher_profile_with_mentor, user: teacher_profile_with_mentor.user)
      FactoryBot.create(:migration_induction_record, participant_profile: mentor)

      teachers = described_class.teachers

      expect(teachers).to include(teacher_profile_with_mentor)
      expect(teachers).not_to include(teacher_profile_with_ect)
    end

    it "includes teacher profiles with both ECT and mentor participant profiles" do
      teacher_profile = FactoryBot.create(:migration_teacher_profile)
      participant_identity = FactoryBot.create(:migration_participant_identity, user: teacher_profile.user)
      mentor = FactoryBot.create(:migration_participant_profile, :mentor, teacher_profile:, user: teacher_profile.user, participant_identity:)
      FactoryBot.create(:migration_induction_record, participant_profile: mentor)
      FactoryBot.create(:migration_induction_record, participant_profile: mentor)

      teachers = described_class.teachers

      expect(teachers).to include(teacher_profile)
      expect(teachers.count).to eq(1)
    end
  end

  describe "#migrate_one!" do
    let(:fake_ecf2_teacher_history) { double(ECF2TeacherHistory, save_all_mentor_data!: true, success?: false) }
    let(:economy_fake_migration_strategy) { double(TeacherHistoryConverter::MigrationStrategy, strategy: :latest_induction_records) }
    let(:premium_fake_migration_strategy) { double(TeacherHistoryConverter::MigrationStrategy, strategy: :all_induction_records) }
    let(:economy_fake_converter) do
      double(
        TeacherHistoryConverter,
        convert_to_ecf2!: fake_ecf2_teacher_history,
        migration_mode: :latest_induction_records
      )
    end
    let(:premium_fake_converter) do
      double(
        TeacherHistoryConverter,
        convert_to_ecf2!: fake_ecf2_teacher_history,
        migration_mode: :all_induction_records
      )
    end

    before do
      allow(TeacherHistoryConverter::MigrationStrategy).to receive(:new).and_return(premium_fake_migration_strategy, economy_fake_migration_strategy)
      allow(TeacherHistoryConverter).to receive(:new).and_return(premium_fake_converter, economy_fake_converter)
    end

    it "falls back to latest_induction_records (economy) if all_induction_records (premium) mode fails" do
      teacher_profile = FactoryBot.create(:migration_teacher_profile)

      participant_identity = FactoryBot.create(:migration_participant_identity, user: teacher_profile.user)
      FactoryBot.create(:migration_participant_profile, :mentor, teacher_profile:, user: teacher_profile.user, participant_identity:)

      migrator = Migrators::Mentor.new
      migrator.migrate_one!(teacher_profile)

      expect(TeacherHistoryConverter).to have_received(:new).twice
      expect(economy_fake_converter).to have_received(:convert_to_ecf2!).once
      expect(premium_fake_converter).to have_received(:convert_to_ecf2!).once
      expect(fake_ecf2_teacher_history).to have_received(:save_all_mentor_data!).twice
    end
  end

  describe "#migrate_one! (part 2)" do
    subject(:teacher) { Teacher.find_by(trn: ecf1_teacher_profile.trn) }

    # Timestamps we care about
    let(:user_created_at) { 3.years.ago.round }

    # ECF1 data
    let(:ecf1_participant_profile) { FactoryBot.create(:migration_participant_profile, :mentor) }
    let(:ecf1_induction_programme) { FactoryBot.create(:migration_induction_programme, :provider_led) }
    let(:ecf1_induction_record) { FactoryBot.create(:migration_induction_record, participant_profile: ecf1_participant_profile, induction_programme: ecf1_induction_programme, created_at: 18.hours.ago.round) }
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
    # let!(:ecf2_school_partnership) { FactoryBot.create(:school_partnership, school: ecf2_school, lead_provider_delivery_partnership: ecf2_lead_provider_delivery_partnership) }

    before do
      DataMigration.create!(worker: 1, model: :mentor)
      migrator = Migrators::Mentor.new(worker: 1)
      migrator.migrate_one!(ecf1_teacher_profile)
    end

    context "when there are errors" do
      let(:migration_mode) { :latest_induction_records }

      it "records the errors" do
        expect(DataMigrationFailedCombination.count).not_to be_zero
      end
    end
  end
end
