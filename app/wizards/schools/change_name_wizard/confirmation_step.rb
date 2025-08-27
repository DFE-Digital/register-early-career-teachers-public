module Schools
  module ChangeNameWizard
    class ConfirmationStep < Step
      def previous_step
        :check_answers
      end
    end
  end
end
