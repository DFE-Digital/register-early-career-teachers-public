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
        return :review_mentor_eligibility if ect.provider_led_training_programme? && mentor.funding_available?

        return :check_answers unless mentor.previously_registered_as_mentor?

        if mentor.has_open_mentor_at_school_period_at_another_school?
          # Ask school: are they mentoring at new school only?
          :mentoring_at_new_school_only
        else
          # Ask school: when will mentor start?
          :started_on
        end
      end

      def previous_step
        :review_mentor_details
      end
    end
  end
end
