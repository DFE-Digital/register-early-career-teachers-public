module Schools
  module RegisterECTWizard
    class TrainingProgrammeChangeLeadProviderStep < LeadProviderStep
      def next_step
        :check_answers
      end

      def previous_step
        :change_training_programme
      end
    end
  end
end
