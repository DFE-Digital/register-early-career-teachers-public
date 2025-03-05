module Schools
  module RegisterECTWizard
    class ChangeEmailAddressStep < EmailAddressStep
      def next_step
        :check_answers
      end

      def previous_step
        :check_answers
      end
    end
  end
end
