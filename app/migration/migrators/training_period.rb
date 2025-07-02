module Migrators
  class TrainingPeriod < Migrators::Base
    def self.record_count
      teachers.count
    end

    def self.model
      :training_period
    end

    def self.teachers
      ::Migration::TeacherProfile.joins(:participant_profiles).merge(Migration::ParticipantProfile.ect_or_mentor).distinct
    end

    def self.dependencies
      %i[ect_at_school_period mentor_at_school_period school_partnership]
    end

    def self.reset!
      if Rails.application.config.enable_migration_testing
        ::TrainingPeriod.connection.execute("TRUNCATE #{::TrainingPeriod.table_name} RESTART IDENTITY CASCADE")
      end
    end

    def migrate!
      migrate(self.class.teachers.eager_load(:user)) do |teacher_profile|
        teacher = ::Teacher.find_by!(trn: teacher_profile.trn)

        result = true

        teacher_profile
          .participant_profiles
          .ect_or_mentor
          .eager_load(induction_records: [induction_programme: [school_cohort: :school]])
          .find_each do |participant_profile|
          induction_records = InductionRecordSanitizer.new(participant_profile:)

          if induction_records.valid?
            training_period_data = TrainingPeriodExtractor.new(induction_records:)
            result = if participant_profile.ect?
                       Builders::ECT::TrainingPeriods.new(teacher:, training_period_data:).build
                     else
                       Builders::Mentor::TrainingPeriods.new(teacher:, training_period_data:).build
                     end
          else
            ::TeacherMigrationFailure.create!(teacher:,
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
