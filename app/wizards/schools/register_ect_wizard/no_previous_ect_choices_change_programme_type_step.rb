module Schools
  module RegisterECTWizard
    class NoPreviousECTChoicesChangeProgrammeTypeStep < ProgrammeTypeStep
      def next_step
        return :no_previous_ect_choices_change_lead_provider if ect.provider_led?

        :check_answers
      end

      def previous_step
        return :no_previous_ect_choices_change_lead_provider if ect.provider_led? && ect.lead_provider_id.nil?
        return :no_previous_ect_choices_change_independent_school_appropriate_body if school.independent?

        :no_previous_ect_choices_change_state_school_appropriate_body
      end
    end
  end
end
