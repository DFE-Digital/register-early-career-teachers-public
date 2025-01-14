module Schools
  module RegisterECTWizard
    class WorkingPatternStep < Step
      attr_accessor :working_pattern

      validates :working_pattern, working_pattern: true

      def self.permitted_params
        %i[working_pattern]
      end

      def next_step
        :check_answers
      end
    end
  end
end
