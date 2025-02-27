module Schools
  module RegisterECTWizard
    class CantUseEmailStep < Step
      def previous_step
        :email_address
      end
    end
  end
end
