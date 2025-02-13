module Schools
  module RegisterECTWizard
    class ChangeStartDateStep < StartDateStep
      def next_step
        :check_answers
      end
    end
  end
end
