module Migrators
  class ECT < Migrators::Base
    def self.record_count
      teachers.count
    end

    def self.model
      :ect
    end

    def self.teachers
      ::Migration::TeacherProfile.joins(:participant_profiles).merge(::Migration::ParticipantProfile.ect).distinct
    end

    def self.dependencies
      %i[mentor]
    end

    def self.reset!
      if Rails.application.config.enable_migration_testing
        ::Teacher.connection.execute("TRUNCATE #{::Teacher.table_name} RESTART IDENTITY CASCADE")
        ::Teacher.connection.execute("TRUNCATE #{::DataMigrationTeacherCombination.table_name} RESTART IDENTITY CASCADE")
        ::Teacher.connection.execute("TRUNCATE #{::DataMigrationFailedCombination.table_name} RESTART IDENTITY CASCADE")
        ::Teacher.connection.execute("TRUNCATE #{::DataMigrationFailedMentorship.table_name} RESTART IDENTITY CASCADE")
      end
    end

    def migrate!
      migrate(self.class.teachers.eager_load(:user)) do |teacher_profile|
        migrate_one!(teacher_profile)
      end
    end

    def migrate_one!(teacher_profile)
      ecf1_teacher_history = ECF1TeacherHistory.build(teacher_profile:)
      return true if ecf1_teacher_history.ect.blank?

      history_converter = TeacherHistoryConverter.new(ecf1_teacher_history:)
      migration_mode = history_converter.migration_mode

      begin
        ecf2_teacher_history = history_converter.convert_to_ecf2!
        Teacher.transaction { ecf2_teacher_history.save_all_ect_data! }
        success = ecf2_teacher_history.success?
      rescue StandardError => e
        failure_manager.record_failure(teacher_profile, e.message, migration_mode)
        success = false
      end

      # if we have tried premium (all_induction_records) and it wasn't a
      # success, fall back to economy (latest_induction_records)
      if !success && migration_mode == :all_induction_records
        begin
          history_converter.set_migration_mode_to_latest_induction_records!

          ecf2_teacher_history = history_converter.convert_to_ecf2!
          Teacher.transaction { ecf2_teacher_history.save_all_ect_data! }
          success = ecf2_teacher_history.success?
        rescue StandardError => e
          failure_manager.record_failure(teacher_profile, e.message, migration_mode)
          success = false
        end
      end

      success
    end

  private

    def preload_caches
      cache_manager.cache_teachers
      cache_manager.cache_schools
      cache_manager.cache_lead_providers
      cache_manager.cache_active_lead_providers
      cache_manager.cache_delivery_partners
      cache_manager.cache_school_partnerships
      cache_manager.cache_lead_provider_delivery_partnerships
    end
  end
end
