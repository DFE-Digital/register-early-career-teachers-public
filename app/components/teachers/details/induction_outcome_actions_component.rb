module Teachers::Details
  # Pass and Fail induction buttons
  class InductionOutcomeActionsComponent < ViewComponent::Base
    attr_reader :mode, :teacher

    def initialize(mode:, teacher:)
      @mode = mode
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
        new_ab_teacher_record_failed_outcome_path(teacher)
      end
    end

    def record_passed_outcome_path
      if admin_mode?
        new_admin_teacher_record_passed_outcome_path(teacher)
      else
        new_ab_teacher_record_passed_outcome_path(teacher)
      end
    end

    def admin_mode?
      mode == :admin
    end
  end
end
