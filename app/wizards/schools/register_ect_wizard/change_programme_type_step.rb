module Schools
  module RegisterECTWizard
    class ChangeProgrammeTypeStep < ProgrammeTypeStep
      def next_step
        return :check_answers if ect.school_led?

        if school.programme_choices? || was_school_led || ect.lead_provider_id.nil?
          ect.update!(previous_step: :change_programme_type)
          return :change_lead_provider
        end

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
