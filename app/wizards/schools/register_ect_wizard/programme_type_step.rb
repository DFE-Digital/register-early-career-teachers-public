module Schools
  module RegisterECTWizard
    class ProgrammeTypeStep < Step
      attr_accessor :programme_type

      validates :programme_type, programme_type: true

      def self.permitted_params
        %i[programme_type]
      end

      def next_step
        ect.provider_led? ? :lead_provider : :check_answers
      end

      def previous_step
        return :independent_school_appropriate_body if school.independent?

        :state_school_appropriate_body
      end

    private

      def persist
        ect.update!(programme_type:)
      end
    end
  end
end
