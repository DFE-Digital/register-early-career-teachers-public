module Migrators
  class MentorAtSchoolPeriod < Migrators::Base
    def self.record_count
      mentor_teachers.count
    end

    def self.model
      :mentor_at_school_period
    end

    def self.mentor_teachers
      ::Migration::TeacherProfile.joins(:participant_profiles).merge(Migration::ParticipantProfile.mentor).where.not(trn: nil).distinct
    end

    def self.dependencies
      %i[teacher school]
    end

    def self.reset!
      if Rails.application.config.enable_migration_testing
        ::MentorAtSchoolPeriod.connection.execute("TRUNCATE #{::MentorAtSchoolPeriod.table_name} RESTART IDENTITY CASCADE")
      end
    end

    def migrate!
      migrate(self.class.mentor_teachers.eager_load(:user)) do |teacher_profile|
        teacher = ::Teacher.find_by!(trn: teacher_profile.trn)

        result = true

        teacher_profile
          .participant_profiles
          .mentor
          .eager_load(induction_records: [induction_programme: [school_cohort: :school]])
          .find_each do |participant_profile|
          sanitizer = InductionRecordSanitizer.new(participant_profile:, group_by: :school)

          school_periods = []

          # TODO: we could just grab the first entry in each school group
          if sanitizer.valid?
            sanitizer.induction_records.each_value do |induction_records_group|
              school_periods << SchoolPeriodExtractor.new(induction_records: induction_records_group).school_periods
            end

            teacher.update!(ecf_mentor_profile_id: participant_profile.id)
            result = Builders::Mentor::SchoolPeriods.new(teacher:, school_periods: school_periods.flatten).build
          else
            ::TeacherMigrationFailure.create!(teacher:,
                                              model: :mentor_at_school_period,
                                              message: sanitizer.error,
                                              migration_item_id: participant_profile.id,
                                              migration_item_type: participant_profile.class.name)
            result = false
          end
        end

        result
      end
    end
  end
end
