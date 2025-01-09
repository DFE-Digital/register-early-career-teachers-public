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
    end
  end
end
