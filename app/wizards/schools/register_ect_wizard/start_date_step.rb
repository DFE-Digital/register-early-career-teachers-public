module Schools
  module RegisterECTWizard
    class StartDateStep < Step
      attr_accessor :start_date

      validates :start_date, ect_start_date: true
      validate :start_date_not_before_previous_school
      validate :start_date_not_before_last_training_period
      validate :start_date_within_4_months, if: :currently_ect_at_another_school?

      def self.permitted_params
        %i[start_date]
      end

      def next_step
        return :cannot_register_ect_yet unless start_date_contract_period

        return :working_pattern if past_start_date? || start_date_contract_period&.enabled?

        :cannot_register_ect_yet
      end

      def previous_step
        :email_address
      end

    private

      def start_date_not_before_previous_school
        return if skip_start_date_validation?

        return unless period_start_date_valid?(previous_period)
        return if start_date_after_period_starts?(previous_period)

        errors.add(
          :start_date,
          "Our records show that #{wizard.ect.full_name} started teaching at #{previous_period.school&.name} on #{previous_period.started_on.to_formatted_s(:govuk)}. Enter a later start date."
        )
      end

      def start_date_not_before_last_training_period
        return if skip_start_date_validation?
        return unless period_start_date_valid?(latest_started_training_period)
        return if start_date_after_period_starts?(latest_started_training_period)

        errors.add(
          :start_date,
          "Our records show that #{wizard.ect.full_name} started their latest training at #{latest_started_training_period.school&.name} on #{latest_started_training_period.started_on.to_formatted_s(:govuk)}. Enter a later start date."
        )
      end

      def start_date_after_period_starts?(period)
        start_date_as_date > period.started_on
      end

      def currently_ect_at_another_school?
        ect.previously_registered? && previous_period.ongoing?
      end

      def previous_period
        ect.previous_ect_at_school_period
      end

      # Unstarted training periods (ie starting today or in the future) will be deleted and should not prevent a start date at a new school from being valid
      def latest_started_training_period
        previous_period&.training_periods&.started_before(Time.zone.today)&.latest_first&.first
      end

      def start_date_within_4_months
        return if skip_start_date_validation?
        return if registrations_closed_for_contract_period?

        earliest_invalid_start_date = (4.months + 1.day).from_now.to_date

        if start_date_as_date >= earliest_invalid_start_date
          errors.add(
            :start_date,
            "Start date must be before #{earliest_invalid_start_date.to_formatted_s(:govuk)}. You cannot register the ECT this far in advance."
          )
        end
      end

      def registrations_closed_for_contract_period?
        start_date_as_date.future? && !start_date_contract_period&.enabled?
      end

      def period_start_date_valid?(period)
        period&.started_on.present?
      end

      def skip_start_date_validation?
        start_date.blank? || errors[:start_date].any?
      end

      def persist
        ect.update!(start_date: start_date_formatted)
        store[:start_date] = start_date_formatted
        store[:start_date_as_date] = start_date_as_date
      end

      def pre_populate_attributes
        self.start_date = Schools::Validation::ECTStartDate.new(date_as_hash: ect.start_date).date_as_hash unless start_date
      end

      def start_date_formatted
        @start_date_formatted ||= start_date_obj.formatted_date
      end

      def start_date_as_date
        @start_date_as_date ||= start_date_obj.value_as_date
      end

      def past_start_date?
        start_date_as_date < Date.current
      end

      def start_date_contract_period
        @start_date_contract_period ||= ContractPeriod.containing_date(start_date_as_date)
      end

      def start_date_obj
        @start_date_obj ||= Schools::Validation::ECTStartDate.new(date_as_hash: start_date)
      end
    end
  end
end
