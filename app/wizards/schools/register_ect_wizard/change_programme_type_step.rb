module Schools
  module RegisterECTWizard
    class ChangeProgrammeTypeStep < ProgrammeTypeStep
      def next_step
        return :lead_provider if ect.provider_led? && was_school_led

        :check_answers
      end

      def previous_step
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
