module Schools
  module RegisterECTWizard
    class ChangeUsePreviousECTChoicesStep < UsePreviousECTChoicesStep
      def next_step
        return :check_answers if use_previous_ect_choices
        return :branch_change_independent_school_appropriate_body if school.independent?

        :branch_change_state_school_appropriate_body
      end

      def previous_step
        :check_answers
      end
    end
  end
end
