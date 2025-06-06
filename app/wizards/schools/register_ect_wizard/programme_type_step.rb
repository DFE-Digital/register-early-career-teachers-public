module Schools
  module RegisterECTWizard
    class ProgrammeTypeStep < Step
      attr_accessor :training_programme

      validates :training_programme, training_programme: true

      def self.permitted_params
        %i[training_programme]
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
        ect.update!(training_programme:)
      end
    end
  end
end
