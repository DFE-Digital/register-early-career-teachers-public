module Schools
  module RegisterECTWizard
    class StartDateStep < Step
      attr_accessor :start_date

      validates :start_date, ect_start_date: true
      validate :start_date_after_previous_school_or_training_period_start
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

      def currently_ect_at_another_school?
        ect.previously_registered? && previous_period.ongoing?
      end

      def previous_period
        ect.previous_ect_at_school_period
      end

      def start_date_after_previous_school_or_training_period_start
        return if skip_start_date_validation?
        return if start_date_boundary_validator.valid?

        errors.add(:start_date, invalid_period_error_message)
      end

      def invalid_period_error_message
        "Our records show that #{wizard.ect.full_name} started " \
        "#{invalid_period_type} at #{previous_period&.school&.name} on " \
        "#{invalid_period_formatted_date}." \
        " Enter a start date after #{invalid_period_earliest_end_date_formatted}."
      end

      def invalid_period_formatted_date
        invalid_period.started_on.to_formatted_s(:govuk)
      end

      def invalid_period_earliest_end_date_formatted
        invalid_period.started_on.next_day.to_formatted_s(:govuk)
      end

      def invalid_period_type
        case invalid_period
        when ECTAtSchoolPeriod then "teaching"
        when TrainingPeriod    then "their latest training"
        end
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

      def invalid_period
        @invalid_period ||= start_date_boundary_validator.invalid_period
      end

      def start_date_boundary_validator
        @start_date_boundary_validator ||= Schools::Validation::PeriodBoundary.new(
          ect_at_school_period: previous_period,
          date: start_date_as_date
        )
      end
    end
  end
end
