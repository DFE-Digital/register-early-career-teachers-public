module Schools
  module RegisterECTWizard
    class ChangeWorkingPatternStep < WorkingPatternStep
      def next_step
        :check_answers
      end
    end
  end
end
