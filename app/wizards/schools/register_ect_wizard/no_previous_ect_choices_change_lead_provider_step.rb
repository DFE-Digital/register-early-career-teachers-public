module Schools
  module RegisterECTWizard
    class NoPreviousECTChoicesChangeLeadProviderStep < LeadProviderStep
      def next_step
        :check_answers
      end

      def previous_step
        return :no_previous_ect_choices_change_programme_type if school.programme_choices? || ect.lead_provider_id.nil?

        :check_answers
      end
    end
  end
end
