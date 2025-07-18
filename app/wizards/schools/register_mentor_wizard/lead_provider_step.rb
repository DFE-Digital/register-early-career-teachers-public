module Schools
  module RegisterMentorWizard
    class LeadProviderStep < Step
      attr_accessor :lead_provider_id

      validates_with LeadProviderValidator

      def self.permitted_params
        %i[lead_provider_id]
      end

      def next_step
        :check_answers
      end

      def previous_step
        :programme_choices
      end

    private

      def persist
        mentor.update!(lead_provider_id:)
      end
    end
  end
end
