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
    subject(:migrator) { described_class.new }

    describe "mentorship period creation", skip: "Add back once we re-implement mentorship migration" do
      # Set up an ECF Migration school that matches the RECT school
      let!(:ecf_migration_school) { FactoryBot.create(:ecf_migration_school) }
      let!(:school) { FactoryBot.create(:school, urn: ecf_migration_school.urn) }

      let(:mentor_profile_id) { SecureRandom.uuid }
      let!(:mentor_teacher) do
        FactoryBot.create(:teacher, api_mentor_training_record_id: mentor_profile_id)
      end
      let!(:mentor_at_school_period) do
        FactoryBot.create(
          :mentor_at_school_period,
          teacher: mentor_teacher,
          school:,
          started_on: 1.year.ago.to_date,
          finished_on: nil
        )
      end

      # Create school_cohort with the migration school
      let(:school_cohort) { FactoryBot.create(:migration_school_cohort, school: ecf_migration_school) }
      let(:ect_teacher_profile) { FactoryBot.create(:migration_teacher_profile) }
      let(:ect_participant_profile) do
        FactoryBot.create(
          :migration_participant_profile,
          :ect,
          teacher_profile: ect_teacher_profile,
          user: ect_teacher_profile.user,
          school_cohort:
        )
      end
      let!(:ect_induction_record) do
        FactoryBot.create(
          :migration_induction_record,
          participant_profile: ect_participant_profile,
          mentor_profile_id:,
          start_date: 6.months.ago.to_date,
          end_date: nil
        )
      end

      it "creates a mentorship period when mentor has been migrated" do
        expect { migrator.migrate_one!(ect_teacher_profile) }.to change(MentorshipPeriod, :count).by(1)
      end

      it "links the mentorship period to the correct mentor" do
        migrator.migrate_one!(ect_teacher_profile)

        mentorship_period = MentorshipPeriod.last
        expect(mentorship_period.mentor).to eq(mentor_at_school_period)
      end

      it "sets the correct dates on the mentorship period" do
        migrator.migrate_one!(ect_teacher_profile)

        mentorship_period = MentorshipPeriod.last
        expect(mentorship_period.started_on).to eq(6.months.ago.to_date)
        expect(mentorship_period.finished_on).to be_nil
      end

      context "when mentor has not been migrated" do
        # Use a different mentor_profile_id that doesn't have a corresponding teacher
        let(:mentor_profile_id) { SecureRandom.uuid }
        let!(:mentor_teacher) { nil }
        let!(:mentor_at_school_period) { nil }

        it "does not create a mentorship period" do
          expect { migrator.migrate_one!(ect_teacher_profile) }.not_to change(MentorshipPeriod, :count)
        end

        it "does not record a mentorship period failure" do
          migrator.migrate_one!(ect_teacher_profile)

          mentorship_failure = TeacherMigrationFailure.find_by(model: "mentorship_period")
          expect(mentorship_failure).to be_nil
        end
      end

      context "when mentor at school period does not exist" do
        # Mentor teacher exists but no MentorAtSchoolPeriod for the school
        let!(:mentor_at_school_period) { nil }

        it "does not create a mentorship period" do
          expect { migrator.migrate_one!(ect_teacher_profile) }.not_to change(MentorshipPeriod, :count)
        end

        it "records a mentorship period failure" do
          migrator.migrate_one!(ect_teacher_profile)

          mentorship_failure = TeacherMigrationFailure.find_by(model: "mentorship_period")
          expect(mentorship_failure).to be_present
          expect(mentorship_failure.message).to eq("No MentorAtSchoolPeriod found for mentorship dates")
        end
      end
    end
  end
end
