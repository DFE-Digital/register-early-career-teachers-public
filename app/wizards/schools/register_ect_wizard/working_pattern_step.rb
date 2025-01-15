module Schools
  module RegisterECTWizard
    class WorkingPatternStep < Step
      attr_accessor :working_pattern

      validates :working_pattern, working_pattern: true

      def self.permitted_params
        %i[working_pattern]
      end

      def next_step
        return :independent_school_appropriate_body if school_independent?

        :state_school_appropriate_body
      end

      def previous_step
        :start_date
      end
    end
  end
end
