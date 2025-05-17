module Schools
  module RegisterECTWizard
    class ProgrammeTypeChangeLeadProviderStep < LeadProviderStep
      def next_step
        :check_answers
      end

      def previous_step
        :change_programme_type
      end
    end
  end
end
