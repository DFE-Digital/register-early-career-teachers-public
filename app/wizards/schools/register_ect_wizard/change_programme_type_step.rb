module Schools
  module RegisterECTWizard
    class ChangeProgrammeTypeStep < ProgrammeTypeStep
      def next_step
        return :check_answers if ect.school_led?
        return :change_lead_provider if school.programme_choices? || was_school_led || ect.lead_provider_id.nil?

        :check_answers
      end

      def previous_step
        return :change_lead_provider if ect.provider_led? && (was_school_led || ect.lead_provider_id.nil?)
        return :change_independent_school_appropriate_body if school.programme_choices? && school.independent?
        return :change_state_school_appropriate_body if school.programme_choices? && school.state_funded?

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
