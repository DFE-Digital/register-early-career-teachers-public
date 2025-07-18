module Schools
  module RegisterECTWizard
    class LeadProviderStep < Step
      attr_accessor :lead_provider_id

      validates :lead_provider_id,
                presence: { message: "Select which lead provider will be training the ECT" },
                lead_provider: { message: "Enter the name of a known lead provider" }

      def self.permitted_params
        %i[lead_provider_id]
      end

      def next_step
        :check_answers
      end

      def previous_step
        :training_programme
      end

    private

      def persist
        ect.update!(lead_provider_id:)
      end
    end
  end
end
