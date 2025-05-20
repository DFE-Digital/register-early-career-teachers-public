module Schools
  module RegisterECTWizard
    class ChangeProgrammeTypeStep < ProgrammeTypeStep
      def next_step
        return :check_answers if ect.school_led?
        return :programme_type_change_lead_provider if was_school_led || ect.lead_provider_id.nil?

        :check_answers
      end

      def previous_step
        return :programme_type_change_lead_provider if ect.provider_led? && ect.lead_provider_id.nil?

        :check_answers
      end

    private

      attr_reader :was_school_led

      def persist
        @was_school_led = ect.programme_type == 'school_led'
        ect.update!(programme_type:)
      end
    end
  end
end
