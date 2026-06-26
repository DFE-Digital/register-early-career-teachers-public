module Admin
  module Teachers
    module TrainingPeriods
      module ChangeContractPeriod
        class AvailableContractPeriods
          FROZEN_CONTRACT_PERIOD_YEARS = [2021, 2022].freeze

          class UnexpectedTrainingPeriodTypeError < StandardError; end

          attr_reader :training_period

          def initialize(training_period:)
            @training_period = training_period
          end

          def contract_periods
            scope = base_scope.most_recent_first
            scope = scope.where.not(year: existing_contract_period.year) if existing_contract_period
            scope = scope.where.not(year: excluded_frozen_years)
            scope = scope.where(year: equivalent_active_lead_providers.select(:contract_period_year)) if eoi_only?
            scope
          end

        private

          def teacher
            training_period.teacher
          end

          def base_scope
            if original_frozen_contract_period_year.in?(FROZEN_CONTRACT_PERIOD_YEARS)
              ContractPeriod.enabled.or(ContractPeriod.where(year: original_frozen_contract_period_year))
            else
              ContractPeriod.enabled
            end
          end

          def excluded_frozen_years
            if original_frozen_contract_period_year.in?(FROZEN_CONTRACT_PERIOD_YEARS)
              FROZEN_CONTRACT_PERIOD_YEARS - [original_frozen_contract_period_year]
            else
              FROZEN_CONTRACT_PERIOD_YEARS
            end
          end

          def existing_contract_period
            @existing_contract_period ||= training_period.contract_period || training_period.expression_of_interest_contract_period
          end

          def eoi_only?
            training_period.only_expression_of_interest?
          end

          def equivalent_active_lead_providers
            ActiveLeadProvider.where(lead_provider: training_period.expression_of_interest_lead_provider)
          end

          def original_frozen_contract_period_year
            if training_period.for_ect?
              teacher.ect_payments_frozen_year
            elsif training_period.for_mentor?
              teacher.mentor_payments_frozen_year
            else
              raise UnexpectedTrainingPeriodTypeError, "Training period was neither ECT nor Mentor"
            end
          end
        end
      end
    end
  end
end
