module Schools
  module RegisterECTWizard
    class WorkingPatternStep < Step
      attr_accessor :working_pattern

      validates :working_pattern, working_pattern: true

      def self.permitted_params
        %i[working_pattern]
      end

      def next_step
        reuse_step = wizard.step_for(:use_previous_ect_choices)
        if school.last_programme_choices? &&
            reuse_step.respond_to?(:allowed?) &&
            reuse_step.allowed?
          :use_previous_ect_choices
        else
          school.independent? ? :independent_school_appropriate_body : :state_school_appropriate_body
        end
      end

      def previous_step
        :start_date
      end
    end
  end
end
