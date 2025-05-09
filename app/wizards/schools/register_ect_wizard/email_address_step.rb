# frozen_string_literal: true

module Schools
  module RegisterECTWizard
    class EmailAddressStep < Step
      attr_accessor :email

      validates :email, presence: { message: "Enter the email address" }, notify_email: true

      def self.permitted_params
        %i[email]
      end

      def next_step
        return :cant_use_email if ect.cant_use_email?

        :start_date
      end

      def previous_step
        if Teacher.find_by_trn(@wizard.ect.trn)&.ect_at_school_periods&.exists?
          :previous_ect_details
        else
          :review_ect_details
        end
      end
    end
  end
end
