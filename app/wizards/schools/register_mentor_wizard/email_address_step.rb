module Schools
  module RegisterMentorWizard
    class EmailAddressStep < Step
      attr_accessor :email

      validates :email, presence: { message: "Enter the email address" }, notify_email: true

      def self.permitted_params
        %i[email]
      end

      def next_step
        return :cant_use_email if mentor.cant_use_email?
        return :review_mentor_eligibility if ect.provider_led_programme_type? && mentor.funding_available?

        :check_answers
      end

      def previous_step
        :review_mentor_details
      end
    end
  end
end
