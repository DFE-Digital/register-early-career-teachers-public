module Teachers::Details
  class InductionOutcomeActionsComponent < ViewComponent::Base
    attr_reader :teacher, :is_admin

    def initialize(teacher:, mode:)
      @teacher = teacher
      @is_admin = mode == :admin
    end

    def record_failed_outcome_url
      if is_admin
        new_admin_teacher_record_failed_outcome_path(teacher)
      else
        new_ab_teacher_record_failed_outcome_path(teacher)
      end
    end

    def record_passed_outcome_url
      if is_admin
        new_admin_teacher_record_passed_outcome_path(teacher)
      else
        new_ab_teacher_record_passed_outcome_path(teacher)
      end
    end
  end
end
