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

    # if we have tried premium (all_induction_records) and it wasn't a
    # success, fall back to economy (latest_induction_records)
    def migrate_one!(teacher_profile)
      success, migration_mode = migrate_one_first_attempt(teacher_profile)
      return success if success || migration_mode == :latest_induction_records

      migrate_one_second_attempt(teacher_profile)
    end

  private

    def migrate_one_first_attempt(teacher_profile)
      history_converter, ecf2_teacher_history = nil

      begin
        Teacher.transaction do
          ecf1_teacher_history = ECF1TeacherHistory.build(teacher_profile:)
          return true if ecf1_teacher_history.mentor.blank?

          history_converter = TeacherHistoryConverter.new(ecf1_teacher_history:)
          ecf2_teacher_history = history_converter.convert_to_ecf2!
        end
      rescue StandardError => e
        failure_manager.record_failure(teacher_profile, e.message, history_converter&.migration_mode)
        return [false, history_converter&.migration_mode]
      end

      save_all_mentor_data!(ecf2_teacher_history:, teacher_profile:, migration_mode: history_converter&.migration_mode)
    end

    def migrate_one_second_attempt(teacher_profile)
      history_converter, ecf2_teacher_history = nil

      begin
        Teacher.transaction do
          ecf1_teacher_history = ECF1TeacherHistory.build(teacher_profile:)
          history_converter = TeacherHistoryConverter.new(ecf1_teacher_history:, migration_mode: :latest_induction_records)
          ecf2_teacher_history = history_converter.convert_to_ecf2!
        end
      rescue StandardError => e
        failure_manager.record_failure(teacher_profile, e.message, :latest_induction_records)
        return [false, :latest_induction_records]
      end

      save_all_mentor_data!(ecf2_teacher_history:, teacher_profile:, migration_mode: :latest_induction_records)
    end

    def preload_caches
      cache_manager.cache_teachers
      cache_manager.cache_schools
      cache_manager.cache_lead_providers
      cache_manager.cache_active_lead_providers
      cache_manager.cache_delivery_partners
      cache_manager.cache_school_partnerships
      cache_manager.cache_lead_provider_delivery_partnerships
    end

    def save_all_mentor_data!(ecf2_teacher_history:, teacher_profile:, migration_mode:)
      Teacher.transaction do
        ecf2_teacher_history.save_all_mentor_data!
        [ecf2_teacher_history.success?, migration_mode]
      end
    rescue StandardError => e
      if e.cause.is_a?(ECF2TeacherHistory::Error)
        ecf2_teacher_history.record_failure!(teacher: e.cause.teacher,
                                             model: e.cause.model,
                                             message: e.cause.message,
                                             migration_item_id: e.cause.migration_item_id)
      else
        failure_manager.record_failure(teacher_profile, e.message, migration_mode)
      end
      [false, migration_mode]
    end
  end
end
