module Schools
  module StartDateStepHelpers
    extend ActiveSupport::Concern

    included do
      delegate :type,
               :started_on_formatted,
               to: :start_date_boundary_validator,
               prefix: :invalid_period

      delegate :earliest_valid_input_date_formatted,
               to: :start_date_boundary_validator
    end

  private

    def start_date_input
      @start_date_input ||=
        Schools::Validation::ECTStartDate.new(
          date_as_hash: start_date
        )
    end

    def start_date_as_date
      @start_date_as_date ||= start_date_input.value_as_date
    end

    def start_date_contract_period
      @start_date_contract_period ||=
        ContractPeriod.containing_date(start_date_as_date)
    end

    def start_date_boundary_validator
      @start_date_boundary_validator ||=
        Schools::Validation::PeriodBoundary.new(
          input_period: previous_period,
          input_date: start_date_as_date
        )
    end
  end
end
