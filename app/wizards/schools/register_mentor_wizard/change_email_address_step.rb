module Schools
  module RegisterMentorWizard
    class ChangeEmailAddressStep < EmailAddressStep
      def previous_step
        return :cant_use_changed_email if mentor.cant_use_email?

        :check_answers
      end

      alias_method :next_step, :previous_step
    end
  end
end
