module Schools
  module RegisterECTWizard
    class ProgrammeTypeStep < Step
      attr_accessor :programme_type

      validates :programme_type, programme_type: true

      def self.permitted_params
        %i[programme_type]
      end

      def next_step
        :working_pattern
      end

      def previous_step
        return :independent_school_appropriate_body if school_independent?

        :state_school_appropriate_body
      end
    end
  end
end
