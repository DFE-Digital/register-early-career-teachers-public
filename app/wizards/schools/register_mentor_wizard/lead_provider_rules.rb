module Schools
  module RegisterMentorWizard
    class LeadProviderRules < ::Rules::Base
      delegate :provider_led_ect?,
               :mentoring_at_new_school_only?,
               :eligible_for_funding?,
               :ect_lead_provider_invalid?,
               :previously_registered_as_mentor?,
               :previous_training_period,
               to: :subject

      def show_row_in_check_your_answers?
        provider_led_ect? && (mentoring_at_new_school_with_funding? || ect_lead_provider_invalid?)
      end

      def needs_selection_for_new_registration?
        !previously_registered_as_mentor? && ect_lead_provider_invalid?
      end

      def previous_step_from_lead_provider
        return :programme_choices unless ect_lead_provider_invalid?

        return :email_address unless previously_registered_as_mentor?

        previous_training_period.present? ? :previous_training_period_details : :started_on
      end

    private

      def mentoring_at_new_school_with_funding? = mentoring_at_new_school_only? && eligible_for_funding?
    end
  end
end
