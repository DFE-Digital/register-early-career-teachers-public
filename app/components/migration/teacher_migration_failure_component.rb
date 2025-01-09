module Migration
  class TeacherMigrationFailureComponent < ViewComponent::Base
    attr_reader :teacher_migration_failure

    def initialize(teacher_migration_failure:)
      @teacher_migration_failure = teacher_migration_failure
    end

    def description
      teacher_migration_failure.message
    end

    def participant_profile
      @participant_profile ||= load_participant_profile
    end

    def induction_records
      participant_profile&.induction_records || []
    end

    def teacher
      @teacher ||= teacher_migration_failure.teacher
    end

  private

    def load_participant_profile
      pid = if teacher_migration_failure.migration_item_type == "Migration::ParticipantProfile"
              teacher_migration_failure.migration_item_id
            elsif teacher.legacy_ect_id.present?
              teacher.legacy_ect_id
            elsif teacher.legacy_mentor_id.present?
              teacher.legacy_mentor_id
            end
      Migration::ParticipantProfilePresenter.new(Migration::ParticipantProfile.find(pid)) if pid.present?
    end
  end
end
