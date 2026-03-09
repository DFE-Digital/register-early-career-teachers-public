RSpec.describe Migrators::ECT do
  describe ".teachers" do
    it "only includes teacher profiles with ECT participant profiles" do
      teacher_profile_with_ect = FactoryBot.create(:migration_teacher_profile)
      ect = FactoryBot.create(:migration_participant_profile, :ect, teacher_profile: teacher_profile_with_ect, user: teacher_profile_with_ect.user)
      FactoryBot.create(:migration_induction_record, participant_profile: ect)

      teacher_profile_with_mentor = FactoryBot.create(:migration_teacher_profile)
      mentor = FactoryBot.create(:migration_participant_profile, :mentor, teacher_profile: teacher_profile_with_mentor, user: teacher_profile_with_mentor.user)
      FactoryBot.create(:migration_induction_record, participant_profile: mentor)

      teachers = described_class.teachers

      expect(teachers).to include(teacher_profile_with_ect)
      expect(teachers).not_to include(teacher_profile_with_mentor)
    end

    it "includes teacher profiles with both ECT and mentor participant profiles" do
      teacher_profile = FactoryBot.create(:migration_teacher_profile)
      participant_identity = FactoryBot.create(:migration_participant_identity, user: teacher_profile.user)
      ect = FactoryBot.create(:migration_participant_profile, :ect, teacher_profile:, user: teacher_profile.user, participant_identity:)
      mentor = FactoryBot.create(:migration_participant_profile, :mentor, teacher_profile:, user: teacher_profile.user, participant_identity:)
      FactoryBot.create(:migration_induction_record, participant_profile: ect)
      FactoryBot.create(:migration_induction_record, participant_profile: mentor)

      teachers = described_class.teachers

      expect(teachers).to include(teacher_profile)
      expect(teachers.count).to eq(1)
    end
  end

  describe "#migrate_one!" do
    let(:fake_ecf2_teacher_history) { double(ECF2TeacherHistory, save_all_ect_data!: true, success?: false) }
    let(:fake_migration_strategy) { double(TeacherHistoryConverter::MigrationStrategy, strategy: :all_induction_records) }
    let(:fake_converter) do
      double(
        TeacherHistoryConverter,
        convert_to_ecf2!: fake_ecf2_teacher_history,
        migration_mode: :all_induction_records,
        set_migration_mode_to_latest_induction_records!: true
      )
    end

    before do
      allow(TeacherHistoryConverter::MigrationStrategy).to receive(:new).and_return(fake_migration_strategy)
      allow(TeacherHistoryConverter).to receive(:new).and_return(fake_converter)
    end

    it "falls back to latest_induction_records (economy) if all_induction_records (premium) mode fails" do
      teacher_profile = FactoryBot.create(:migration_teacher_profile)

      participant_identity = FactoryBot.create(:migration_participant_identity, user: teacher_profile.user)
      FactoryBot.create(:migration_participant_profile, :ect, teacher_profile:, user: teacher_profile.user, participant_identity:)

      migrator = Migrators::ECT.new
      migrator.migrate_one!(teacher_profile)

      expect(fake_converter).to have_received(:convert_to_ecf2!).twice
      expect(fake_converter).to have_received(:set_migration_mode_to_latest_induction_records!).once
      expect(fake_ecf2_teacher_history).to have_received(:save_all_ect_data!).twice
    end
  end
end
