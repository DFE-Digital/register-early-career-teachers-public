module Schools
  module RegisterMentorWizard
    class EligibilityLeadProviderStep < LeadProviderStep
      def next_step
        :check_answers
      end

      def previous_step
        :review_mentor_eligibility
      end
    end
  end
end
