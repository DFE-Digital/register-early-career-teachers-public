module Migrators
  class Mentor < Migrators::Base
    def self.record_count
      teachers.count
    end

    def self.model
      :mentor
    end

    def self.teachers
      ::Migration::TeacherProfile.joins(:participant_profiles).merge(::Migration::ParticipantProfile.mentor).distinct
    end

    def self.dependencies
      %i[schedule school_partnership]
    end

    def self.reset!
      # Reset is handled by ECT which truncates the Teacher, DataMigrationTeacherCombination
      # and DataMigrationFailedCombination tables
    end

    def migrate!
      migrate(self.class.teachers.eager_load(:user)) do |teacher_profile|
        migrate_one!(teacher_profile)
      end
    end

    def migrate_one!(teacher_profile)
      ecf1_teacher_history = ECF1TeacherHistory.build(teacher_profile:)
      return true if ecf1_teacher_history.mentor.blank?

      ecf2_teacher_history = TeacherHistoryConverter.new(ecf1_teacher_history:).convert_to_ecf2!
      ecf2_teacher_history.save_all_mentor_data!
      ecf2_teacher_history.success?
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
