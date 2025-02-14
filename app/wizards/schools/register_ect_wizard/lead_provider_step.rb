module Schools
  module RegisterECTWizard
    class LeadProviderStep < Step
      attr_accessor :lead_provider_id

      validates :lead_provider_id, presence: {
        message: "Enter the name of the lead provider which will be supporting the ECT's induction"
      }

      def self.permitted_params
        %i[lead_provider_id]
      end

      def next_step
        :check_answers
      end

      def previous_step
        :programme_type
      end

      def persist
        ect.update!(lead_provider_id:)
      end
    end
  end
end
