module Schools
  module RegisterMentorWizard
    class LeadProviderRules < ::Rules::Base
      def show_row_in_check_your_answers?
        subject.provider_led_ect? &&
          ((subject.mentoring_at_new_school_only? && subject.funding_available?) ||
           subject.ect_lead_provider_invalid?)
      end

      def needs_selection_for_new_registration?
        !subject.previously_registered_as_mentor? && subject.ect_lead_provider_invalid?
      end

      def previous_step_from_lead_provider
        return :email_address if subject.ect_lead_provider_invalid? && !subject.previously_registered_as_mentor?
        return :previous_training_period_details if subject.ect_lead_provider_invalid? && subject.previously_registered_as_mentor?

        :programme_choices
      end
    end
  end
end
