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
end
