module Migrators
  class Teacher < Migrators::Base
    def self.record_count
      teachers.count
    end

    def self.model
      :teacher
    end

    def self.teachers
      ::Migration::TeacherProfile.joins(:participant_profiles).merge(::Migration::ParticipantProfile.ect_or_mentor).distinct
    end

    def self.dependencies
      %i[schedule school_partnership]
    end

    def self.reset!
      if Rails.application.config.enable_migration_testing
        ::Teacher.connection.execute("TRUNCATE #{::Teacher.table_name} RESTART IDENTITY CASCADE")
      end
    end

    def migrate!
      migrate(self.class.teachers.eager_load(:user)) do |teacher_profile|
        Rails.logger.debug("Migrating --------")
        Rails.logger.debug("Migrating teacher #{teacher_profile.trn}")

        outcome = migrate_one!(teacher_profile)

        Rails.logger.debug("Migrating teacher #{teacher_profile.trn}: #{outcome}")
      end
    end

    def migrate_one!(teacher_profile)
      ecf1_teacher_history = ECF1TeacherHistory.build(teacher_profile:)

      ecf2_teacher_history = TeacherHistoryConverter.new(ecf1_teacher_history:).convert_to_ecf2!

      ecf2_teacher_history.save_all_ect_data!
    end
  end
end
