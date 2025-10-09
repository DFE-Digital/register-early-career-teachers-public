module Schools
  module RegisterECTWizard
    class CantUseChangedEmailStep < Step
      def next_step
        :change_email_address
      end

      def previous_step
        :change_email_address
      end
    end
  end
end
