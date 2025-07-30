module Migrators
  class ECTAtSchoolPeriod < Migrators::Base
    def self.record_count
      ect_teachers.count
    end

    def self.model
      :ect_at_school_period
    end

    def self.ect_teachers
      ::Migration::TeacherProfile.joins(:participant_profiles).merge(Migration::ParticipantProfile.ect).distinct
    end

    def self.dependencies
      %i[teacher school]
    end

    def self.reset!
      if Rails.application.config.enable_migration_testing
        ::ECTAtSchoolPeriod.connection.execute("TRUNCATE #{::ECTAtSchoolPeriod.table_name} RESTART IDENTITY CASCADE")
      end
    end

    def migrate!
      migrate(self.class.ect_teachers.eager_load(:user)) do |teacher_profile|
        teacher = ::Teacher.find_by!(trn: teacher_profile.trn)

        result = true

        teacher_profile
          .participant_profiles
          .ect
          .eager_load(induction_records: [induction_programme: [school_cohort: :school]])
          .find_each do |participant_profile|
          sanitizer = InductionRecordSanitizer.new(participant_profile:, group_by: :school)

          school_periods = []

          # TODO: we could just grab the first entry in each school group
          if sanitizer.valid?
            sanitizer.induction_records.each do |urn, irs|
              school_periods << SchoolPeriodExtractor.new(induction_records: irs).school_periods
            end

            teacher.update!(ecf_ect_profile_id: participant_profile.id)
            result = Builders::ECT::SchoolPeriods.new(teacher:, school_periods: school_periods.flatten).build
          else
            ::TeacherMigrationFailure.create!(teacher:,
                                              model: :ect_at_school_period,
                                              message: induction_records.error,
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
