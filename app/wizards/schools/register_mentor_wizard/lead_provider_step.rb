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
        if mentor.ect_lead_provider_invalid?
          :email_address
        else
          :programme_choices
        end
      end

    private

      def persist
        mentor.update!(lead_provider_id:)
      end
    end
  end
end
