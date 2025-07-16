module Schools
  module RegisterMentorWizard
    class StartedOnStep < Step
      attribute :started_on, :date

      validates :started_on, presence: { message: "Enter a start date" }

      def self.permitted_params
        %i[started_on]
      end

      def next_step
        return :check_answers unless mentor_assigned_to_provider_led_ect?

        if mentor_became_ineligible_for_funding?
          :check_answers
        elsif mentor.latest_registration_choice.training_period
          :previous_training_period_details
        else
          :programme_choices
        end
      end

      def previous_step
        if mentor.mentoring_at_new_school_only == "yes"
          :mentoring_at_new_school_only
        else
          :email_address
        end
      end

    private

      # Is mentor being assigned to a provider-led ECT?
      def mentor_assigned_to_provider_led_ect?
        ect.provider_led?
      end

      # Does that mentor have a mentor_became_ineligible_for_funding_on?
      def mentor_became_ineligible_for_funding?
        ::Teachers::MentorFundingEligibility.new(trn: mentor.trn).ineligible?
      end

      def persist
        mentor.update(started_on:)
      end

      def pre_populate_attributes
        self.started_on ||= mentor.started_on
      end
    end
  end
end
