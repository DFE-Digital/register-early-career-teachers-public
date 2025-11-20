module Schools
  module RegisterMentorWizard
    class EligibilityLeadProviderStep < LeadProviderStep
      def next_step
        wizard.store.back_to = "eligibility_lead_provider"
        :check_answers
      end

      def previous_step
        :review_mentor_eligibility
      end
    end
  end
end
