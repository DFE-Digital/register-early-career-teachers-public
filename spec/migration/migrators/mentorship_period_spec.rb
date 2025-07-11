RSpec.describe Migrators::MentorshipPeriod do
  it_behaves_like "a migrator", :mentorship_period, %i[ect_at_school_period mentor_at_school_period] do
    def create_migration_resource
      ect = FactoryBot.create(:migration_participant_profile, :ect)
      mentor = FactoryBot.create(:migration_participant_profile, :mentor, school_cohort: ect.school_cohort)
      FactoryBot.create(:migration_induction_record, participant_profile: mentor, start_date: 1.week.ago, end_date: nil)
      FactoryBot.create(:migration_induction_record, participant_profile: ect, mentor_profile: mentor, start_date: 1.week.ago, end_date: nil)
      ect.teacher_profile
    end

    def create_resource(migration_resource)
      ect = FactoryBot.create(:teacher, trn: migration_resource.trn, ecf_ect_profile_id: migration_resource.participant_profiles.first.id)
      school = FactoryBot.create(:school, urn: migration_resource.participant_profiles.first.school_cohort.school.urn)
      FactoryBot.create(:ect_at_school_period, teacher: ect, school:, started_on: migration_resource.participant_profiles.first.induction_records.first.start_date, finished_on: nil)

      migration_mentor = Migration::ParticipantProfile.find_by(teacher_profile: migration_resource).induction_records.first.mentor_profile
      mentor = FactoryBot.create(:teacher, trn: migration_mentor.teacher_profile.trn, ecf_mentor_profile_id: migration_mentor.id)
      FactoryBot.create(:mentor_at_school_period, teacher: mentor, school:, started_on: migration_mentor.induction_records.first.start_date, finished_on: nil)
    end

    def setup_failure_state
      # add but with no dependencies added
      create_migration_resource
    end

    describe "#migrate!" do
      it 'creates a MentorshipPeriod record for each mentorship period found in the ECF induction records' do
        instance.migrate!

        Migration::ParticipantProfile.ect.find_each do |participant_profile|
          teacher_profile = participant_profile.teacher_profile
          teacher = ::Teacher.find_by!(trn: teacher_profile.trn)
          mentorship_period = teacher.ect_at_school_periods.first.mentorship_periods.first

          participant_profile.induction_records.each do |induction_record|
            expect(mentorship_period.started_on.to_date).to eq induction_record.start_date.to_date
            expect(mentorship_period.mentor.teacher.trn).to eq induction_record.mentor_profile.teacher_profile.trn
          end
        end
      end
    end
  end
end
