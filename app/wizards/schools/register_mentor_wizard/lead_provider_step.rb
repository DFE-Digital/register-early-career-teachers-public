module Schools
  module RegisterMentorWizard
    class LeadProviderStep < Step
      attr_accessor :lead_provider_id

      validates :lead_provider_id,
                presence: { message: "Select a lead provider to contact your school" },
                lead_provider: { message: "Select a lead provider to contact your school" }

      def self.permitted_params
        %i[lead_provider_id]
      end

      def next_step
        :check_answers
      end

      def previous_step
        return :email_address if mentor.ect_lead_provider_invalid? && !mentor.previously_registered_as_mentor?
        return :previous_training_period_details if mentor.ect_lead_provider_invalid? && mentor.previously_registered_as_mentor?

        :programme_choices
      end

    private

      def persist
        mentor.update!(lead_provider_id:)
      end
    end
  end
end
