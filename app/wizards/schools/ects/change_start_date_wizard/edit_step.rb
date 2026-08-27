module Schools
  module ECTs
    module ChangeStartDateWizard
      class EditStep < ECTs::Step
        attr_accessor :start_date

        validates :start_date, ect_start_date: true
        validate :start_date_must_be_different
        validate :start_date_after_previous_school_or_training_period_start
        validate :start_date_within_4_months
        validate :start_date_on_or_before_leaving_date

        def self.permitted_params
          %i[start_date]
        end

        def next_step
          return :cannot_use_date unless start_date_contract_period

          if start_date_as_date.past? ||
              start_date_contract_period.enabled?
            :check_answers
          else
            :cannot_use_date
          end
        end

        def save!
          return false unless valid_step?

          store.start_date = start_date_input.date_as_hash
        end

      private

        def pre_populate_attributes
          return unless store.start_date

          self.start_date = Schools::Validation::ECTStartDate
            .new(date_as_hash: store.start_date)
            .date_as_hash
        end

        def start_date_after_previous_school_or_training_period_start
          return if skip_additional_start_date_validations?
          return if start_date_boundary_validator.valid?

          errors.add(
            :start_date,
            invalid_period_error_message
          )
        end

        def start_date_must_be_different
          return if skip_additional_start_date_validations?
          return unless start_date_as_date == ect_at_school_period.started_on

          errors.add(
            :start_date,
            "The school start date must be different from the current school start date"
          )
        end

        def invalid_period_error_message
          "Our records show that " \
            "#{name_for(ect_at_school_period.teacher)} started " \
            "#{invalid_period_type} at #{previous_period.school.name} on " \
            "#{invalid_period_started_on_formatted}. " \
            "Enter a start date after " \
            "#{earliest_valid_input_date_formatted}."
        end

        def start_date_within_4_months
          return if skip_additional_start_date_validations?
          return if registrations_closed_for_contract_period?
          return if start_date_as_date < earliest_invalid_start_date

          errors.add(
            :start_date,
            "Start date must be before " \
              "#{earliest_invalid_start_date.to_fs(:govuk)}. " \
              "You cannot register the ECT this far in advance."
          )
        end

        def start_date_on_or_before_leaving_date
          return if skip_additional_start_date_validations?
          return unless ect_at_school_period.finished_on
          return if start_date_as_date <= ect_at_school_period.finished_on

          errors.add(
            :start_date,
            "Enter a start date on or before " \
              "#{ect_at_school_period.finished_on.to_fs(:govuk)}"
          )
        end

        def registrations_closed_for_contract_period?
          start_date_as_date.future? &&
            !start_date_contract_period&.enabled?
        end

        def skip_additional_start_date_validations?
          start_date.blank? || errors[:start_date].any?
        end

        def earliest_invalid_start_date
          @earliest_invalid_start_date ||=
            (4.months + 1.day).from_now.to_date
        end

        def previous_period
          @previous_period ||=
            ect_at_school_period
              .teacher
              .ect_at_school_periods
              .where.not(id: ect_at_school_period.id)
              .latest_first
              .first
        end

        def start_date_boundary_validator
          @start_date_boundary_validator ||=
            Schools::Validation::PeriodBoundary.new(
              input_period: previous_period,
              input_date: start_date_as_date
            )
        end

        def start_date_input
          @start_date_input ||=
            Schools::Validation::ECTStartDate.new(
              date_as_hash: start_date
            )
        end

        def start_date_as_date
          start_date_input.value_as_date
        end

        def start_date_contract_period
          @start_date_contract_period ||=
            ContractPeriod.containing_date(start_date_as_date)
        end

        delegate :type,
                 :started_on_formatted,
                 to: :start_date_boundary_validator,
                 prefix: :invalid_period

        delegate :earliest_valid_input_date_formatted,
                 to: :start_date_boundary_validator
      end
    end
  end
end
