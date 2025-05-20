module Schools
  module RegisterECTWizard
    class ChangeLeadProviderStep < LeadProviderStep
      def next_step
        :check_answers
      end

      def previous_step
        :check_answers
      end
    end
  end
end
