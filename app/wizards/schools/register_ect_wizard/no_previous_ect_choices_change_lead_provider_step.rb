module Schools
  module RegisterECTWizard
    class NoPreviousECTChoicesChangeLeadProviderStep < LeadProviderStep
      def next_step
        :check_answers
      end

      def previous_step
        :no_previous_ect_choices_change_training_programme
      end
    end
  end
end
