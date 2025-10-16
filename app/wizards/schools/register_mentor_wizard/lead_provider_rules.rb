module Schools
  module RegisterMentorWizard
    class LeadProviderRules < ::Rules::Base
      delegate :provider_led_ect?,
        :mentoring_at_new_school_only?,
        :funding_available?,
        :ect_lead_provider_invalid?,
        :previously_registered_as_mentor?,
        to: :subject

      def show_row_in_check_your_answers?
        provider_led_ect? && (mentoring_at_new_school_with_funding? || ect_lead_provider_invalid?)
      end

      def needs_selection_for_new_registration?
        !previously_registered_as_mentor? && ect_lead_provider_invalid?
      end

      def previous_step_from_lead_provider
        return :programme_choices unless ect_lead_provider_invalid?

        previously_registered_as_mentor? ? :previous_training_period_details : :email_address
      end

      private

      def mentoring_at_new_school_with_funding? = mentoring_at_new_school_only? && funding_available?
    end
  end
end
