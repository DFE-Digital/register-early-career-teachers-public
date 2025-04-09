module Schools
  module RegisterMentorWizard
    class ChangeEmailAddressStep < EmailAddressStep
      def previous_step
        :check_answers
      end

      def next_step
        return :cant_use_changed_email if mentor.cant_use_email?

        :check_answers
      end
    end
  end
end
