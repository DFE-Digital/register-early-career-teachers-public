module Schools
  module RegisterMentorWizard
    class EmailAddressStep < Step
      attr_accessor :email

      validates :email, presence: { message: "Enter the email address" }, notify_email: true

      def self.permitted_params
        %i[email]
      end

      class IneligibleForReview < StandardError; end
      class InvalidMentorshipStatus < StandardError; end

      def next_step
        return :cant_use_email if mentor.cant_use_email?
        return :review_mentor_eligibility if eligible_for_review?
        return :lead_provider if lead_provider_rules.needs_selection_for_new_registration?
        return :check_answers unless mentor.previously_registered_as_mentor?

        case mentor.mentorship_status
        when :currently_a_mentor then :mentoring_at_new_school_only
        when :previously_a_mentor then :started_on
        else
          raise InvalidMentorshipStatus, "Unexpected status: #{mentor.mentorship_status.inspect}"
        end
      end

      def previous_step
        :review_mentor_details
      end

      def lead_provider_rules
        Schools::RegisterMentorWizard::LeadProviderRules.new(mentor)
      end

    private

      def eligible_for_review?
        ect.provider_led_training_programme? && mentor.funding_available? && !mentor.previously_registered_as_mentor? && !mentor.ect_lead_provider_invalid?
      end

      def persist
        super

        mentor.update!(lead_provider_id: mentor.ect_lead_provider&.id)
      end
    end
  end
end
