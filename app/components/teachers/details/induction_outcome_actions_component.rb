module Teachers::Details
  # Pass and Fail induction buttons
  class InductionOutcomeActionsComponent < ApplicationComponent
    include UserModes

    attr_reader :teacher

    def initialize(mode:, teacher:)
      super

      @teacher = teacher
    end

    def render?
      Teachers::InductionPeriod.new(teacher).ongoing_induction_period.present?
    end

  private

    def record_failed_outcome_path
      if admin_mode?
        new_admin_teacher_record_failed_outcome_path(teacher)
      else
        confirm_failed_outcome_ab_teacher_record_failed_outcome_path(teacher)
      end
    end

    def record_passed_outcome_path
      if admin_mode?
        new_admin_teacher_record_passed_outcome_path(teacher)
      else
        new_ab_teacher_record_passed_outcome_path(teacher)
      end
    end
  end
end
