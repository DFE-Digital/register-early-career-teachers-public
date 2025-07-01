RSpec.describe Migrators::ECTAtSchoolPeriod do
  it_behaves_like "a migrator", :ect_at_school_period, %i[teacher school] do
    def create_migration_resource
      ect = FactoryBot.create(:migration_participant_profile, :ect)
      FactoryBot.create(:migration_induction_record, participant_profile: ect)
      ect.teacher_profile
    end

    def create_resource(migration_resource)
      FactoryBot.create(:teacher, trn: migration_resource.trn)
      FactoryBot.create(:school, urn: migration_resource.participant_profiles.first.school_cohort.school.urn)
    end

    def setup_failure_state
      # add but with no dependencies added
      create_migration_resource
    end

    describe "#migrate!" do
      it 'creates an ECTAtSchoolPeriod records for each school period found in the ECF induction records' do
        instance.migrate!

        Migration::TeacherProfile.find_each do |teacher_profile|
          teacher = ::Teacher.find_by!(trn: teacher_profile.trn)

          teacher_profile.participant_profiles.first.induction_records.each do |induction_record|
            expect(teacher.ect_at_school_periods.first.started_on.to_date).to eq induction_record.start_date.to_date
            expect(teacher.ect_at_school_periods.first.school.urn).to eq induction_record.induction_programme.school_cohort.school.urn.to_i
          end
        end
      end
    end
  end
end
