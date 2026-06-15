module Admin
  module Teachers
    module TrainingPeriods
      module ChangeContractPeriodWizard
        class CheckAnswersStep < Step
          self.expected_store_keys = %i[contract_period_year school_partnership_id]

          def previous_step = :select_partnership

          def save! = true
        end
      end
    end
  end
end
