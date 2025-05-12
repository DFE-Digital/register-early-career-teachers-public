module Schools
  module RegisterECTWizard
    class ProgrammeTypeChangeLeadProviderStep < LeadProviderStep
      def next_step
        :check_answers
      end

      def previous_step
        return :change_provider_led_programme_type if school.programme_choices? || ect.lead_provider_id.nil?

        :check_answers
      end
    end
  end
end
