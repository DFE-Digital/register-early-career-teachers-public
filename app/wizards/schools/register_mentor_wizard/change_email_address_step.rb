module Schools
  module RegisterMentorWizard
    class ChangeEmailAddressStep < EmailAddressStep
      def previous_step
        :check_answers
      end

      def next_step
        :check_answers
      end
    end
  end
end
