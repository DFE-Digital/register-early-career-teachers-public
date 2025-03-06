module Schools
  module RegisterECTWizard
    class ChangeProgrammeTypeStep < ProgrammeTypeStep
      def next_step
        :check_answers
      end

      def previous_step
        :check_answers
      end
    end
  end
end
