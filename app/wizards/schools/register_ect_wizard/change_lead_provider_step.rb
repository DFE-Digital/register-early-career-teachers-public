module Schools
  module RegisterECTWizard
    class ChangeLeadProviderStep < LeadProviderStep
      def next_step
        :check_answers
      end

      def previous_step
        if ect.previous_step
          return ect.previous_step&.to_sym
        end

        :check_answers
      end
    end
  end
end
