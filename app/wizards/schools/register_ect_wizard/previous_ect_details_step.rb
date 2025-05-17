module Schools
  module RegisterECTWizard
    class PreviousECTDetailsStep < Step
      def next_step
        :email_address
      end

      def previous_step
        :review_ect_details
      end
    end
  end
end
