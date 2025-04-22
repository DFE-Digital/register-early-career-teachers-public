module Migrators
  class Teacher < Migrators::Base
    def self.record_count
      teachers.count
    end

    def self.model
      :teacher
    end

    def self.teachers
      ::Migration::TeacherProfile.joins(:participant_profiles).merge(Migration::ParticipantProfile.ect_or_mentor).distinct
    end

    def self.dependencies
      %i[school_partnership]
    end

    def self.records_per_worker
      1_000
    end

    def self.reset!
      if Rails.application.config.enable_migration_testing
        ::Teacher.connection.execute("TRUNCATE #{::Teacher.table_name} RESTART IDENTITY CASCADE")
      end
    end

    def migrate!
      migrate(self.class.teachers.eager_load(:user)) do |teacher_profile|
        safe_migrate_teacher(teacher_profile:)
      end
    end

    def safe_migrate_teacher(teacher_profile:)
      trn = teacher_profile.trn
      full_name = teacher_profile.user.full_name

      builder = Builders::Teacher.new(trn:, full_name:, ecf_user_id: teacher_profile.user_id)
      teacher = builder.build
      if teacher.nil?
        failure_manager.record_failure(teacher_profile, builder.error)
        return false
      end

      success = true

      teacher_profile
        .participant_profiles
        .ect_or_mentor
        .eager_load(induction_records: [induction_programme: [school_cohort: :school]])
        .find_each do |participant_profile|
          induction_records = InductionRecordSanitizer.new(participant_profile:)

          if induction_records.valid?
            sp_success = tp_success = false
            school_periods = SchoolPeriodExtractor.new(induction_records:)
            training_period_data = TrainingPeriodExtractor.new(induction_records:)

            if participant_profile.ect?
              teacher.update!(ecf_ect_profile_id: participant_profile.id)
              sp_success = Builders::ECT::SchoolPeriods.new(teacher:, school_periods:).build
              tp_success = Builders::ECT::TrainingPeriods.new(teacher:, training_period_data:).build
            else
              teacher.update!(ecf_mentor_profile_id: participant_profile.id)
              sp_success = Builders::Mentor::SchoolPeriods.new(teacher:, school_periods:).build
              tp_success = Builders::Mentor::TrainingPeriods.new(teacher:, training_period_data:).build
            end
            success = false unless sp_success && tp_success
          else
            ::TeacherMigrationFailure.create!(teacher:,
                                              message: induction_records.error,
                                              migration_item_id: participant_profile.id,
                                              migration_item_type: participant_profile.class.name)
            success = false
          end
        end

      success
    end
  end
end
