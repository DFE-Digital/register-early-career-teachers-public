RSpec.describe Migrators::MentorAtSchoolPeriod do
  it_behaves_like "a migrator", :mentor_at_school_period, %i[teacher school] do
    def create_migration_resource
      mentor = create(:migration_participant_profile, :mentor)
      create(:migration_induction_record, participant_profile: mentor)
      mentor.teacher_profile
    end

    def create_resource(migration_resource)
      create(:teacher, trn: migration_resource.trn)
      create(:school, urn: migration_resource.participant_profiles.first.school_cohort.school.urn)
    end

    def setup_failure_state
      # add but with no dependencies added
      create_migration_resource
    end

    describe "#migrate!" do
      it 'creates a MentorAtSchoolPeriod records for each school period found in the ECF induction records' do
        instance.migrate!

        Migration::TeacherProfile.find_each do |teacher_profile|
          teacher = ::Teacher.find_by!(trn: teacher_profile.trn)

          teacher_profile.participant_profiles.first.induction_records.each do |induction_record|
            expect(teacher.mentor_at_school_periods.first.started_on.to_date).to eq induction_record.start_date.to_date
            expect(teacher.mentor_at_school_periods.first.school.urn).to eq induction_record.induction_programme.school_cohort.school.urn.to_i
          end
        end
      end
    end
  end
end
