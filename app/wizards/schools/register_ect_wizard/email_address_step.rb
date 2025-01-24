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
        :start_date
      end

      def previous_step
        :review_ect_details
      end
    end
  end
end
