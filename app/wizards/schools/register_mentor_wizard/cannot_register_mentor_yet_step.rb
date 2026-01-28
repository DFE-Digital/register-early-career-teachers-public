module Schools
  module RegisterMentorWizard
    class CannotRegisterMentorYetStep < Step
      def previous_step
        :started_on
      end
    end
  end
end
