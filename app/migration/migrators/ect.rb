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

      ecf2_teacher_history = TeacherHistoryConverter.new(ecf1_teacher_history:).convert_to_ecf2!
      ecf2_teacher_history.save_all_ect_data!
      true
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
