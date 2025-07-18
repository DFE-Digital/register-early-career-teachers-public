module Schools
  module RegisterMentorWizard
    class StartedOnStep < Step
      attribute :started_on, :date

      validates :started_on, presence: { message: "Enter the date they started or will start ECT mentoring at your school" }
      validate :started_on_cannot_be_before_previous_started_and_finished_dates, if: :started_on

      def self.permitted_params
        %i[started_on]
      end

      def next_step
        return :check_answers unless mentor.provider_led_ect?

        if mentor.became_ineligible_for_funding?
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

      def persist
        mentor.update(started_on:)
      end

      def pre_populate_attributes
        self.started_on ||= mentor.started_on
      end

      def started_on_cannot_be_before_previous_started_and_finished_dates
        return if errors.any?

        date = mentor.previous_school_mentor_at_school_periods.pluck(:started_on, :finished_on).flatten.compact.max
        return unless date

        if started_on.before?(date.next_day)
          errors.add(:started_on, "#{mentor.full_name} was registered as a mentor #{date.to_fs(:govuk)}. Enter a later date.")
        end
      end
    end
  end
end
