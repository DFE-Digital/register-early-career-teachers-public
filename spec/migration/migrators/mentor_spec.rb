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
end
