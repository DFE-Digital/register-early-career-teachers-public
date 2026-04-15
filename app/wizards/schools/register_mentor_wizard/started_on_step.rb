module Schools
  module RegisterMentorWizard
    class StartedOnStep < Step
      attr_accessor :started_on

      validates :started_on, mentor_start_date: true
      validate :started_on_after_all_previous_period_started_on_dates
      validate :started_on_within_4_months, if: :currently_mentor_at_another_school?

      def self.permitted_params = %i[started_on]

      def next_step
        if registrations_closed_for_contract_period?
          :cannot_register_mentor_yet
        elsif mentor.became_ineligible_for_funding? || !mentor.provider_led_ect?
          :check_answers
        elsif mentor.previous_training_period.blank?
          :programme_choices # if previous registration school led
        else
          :previous_training_period_details
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

      delegate :currently_mentor_at_another_school?, to: :mentor

      def persist
        mentor.update!(started_on: started_on_formatted)
      end

      def pre_populate_attributes
        self.started_on = Schools::Validation::MentorStartDate.new(date_as_hash: mentor.started_on).date_as_hash unless started_on
      end

      def started_on_after_all_previous_period_started_on_dates
        return if errors.any?

        latest_started_on_at_previous_school = mentor
          .previous_school_mentor_at_school_periods
          .maximum(:started_on)
        return unless latest_started_on_at_previous_school

        unless started_on_as_date.after?(latest_started_on_at_previous_school)
          error_message = <<~TXT.squish
            #{mentor.full_name} was registered as a mentor at their last school
            starting on the #{latest_started_on_at_previous_school.to_fs(:govuk)}.
            Enter a later date.
          TXT
          errors.add(:started_on, error_message)
        end
      end

      def started_on_within_4_months
        return if errors.any?

        earliest_invalid_started_on = 4.months.from_now.to_date.next_day

        unless started_on_as_date.before?(earliest_invalid_started_on)
          errors.add(
            :started_on,
            "Start date must be before #{earliest_invalid_started_on.to_formatted_s(:govuk)}"
          )
        end
      end

      def started_on_formatted
        @started_on_formatted ||= started_on_obj.formatted_date
      end

      def started_on_obj
        @started_on_obj ||= Schools::Validation::MentorStartDate.new(date_as_hash: started_on)
      end

      def started_on_as_date
        @started_on_as_date ||= started_on_obj.value_as_date
      end

      def registrations_closed_for_contract_period?
        started_on_as_date.future? && !contract_period&.enabled?
      end

      def contract_period
        @contract_period ||= ContractPeriod.containing_date(started_on_as_date)
      end
    end
  end
end
