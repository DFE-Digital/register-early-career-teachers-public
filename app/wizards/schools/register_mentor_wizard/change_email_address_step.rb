module Schools
  module RegisterMentorWizard
    class ChangeEmailAddressStep < EmailAddressStep
      def previous_step
        return :cant_use_changed_email if mentor.email_taken?

        :check_answers
      end

      alias_method :next_step, :previous_step
    end
  end
end
