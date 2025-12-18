module Schools
  module RegisterECTWizard
    class ChangeStartDateStep < StartDateStep
      def next_step
        if school.last_programme_choices? && wizard.use_previous_choices_allowed?
          :use_previous_ect_choices
        elsif school.independent?
          :independent_school_appropriate_body
        else
          :state_school_appropriate_body
        end
      end

      def previous_step
        :check_answers
      end

      def save!
        super.tap do |result|
          next unless result

          reset_reuse_state!
        end
      end

    private

      def reset_reuse_state!
        ect.use_previous_ect_choices = nil
        wizard.store[:school_partnership_to_reuse_id] = nil

        return if wizard.use_previous_choices_allowed?

        ect.appropriate_body_id = nil
        ect.training_programme = nil
        ect.lead_provider_id = nil
      end
    end
  end
end
