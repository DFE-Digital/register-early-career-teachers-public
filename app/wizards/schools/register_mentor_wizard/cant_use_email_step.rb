module Schools
  module RegisterMentorWizard
    class CantUseEmailStep < Step
      def next_step
        :email_address
      end

      def previous_step
        :email_address
      end
    end
  end
end
