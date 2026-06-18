module Admin
  module Teachers
    module TrainingPeriods
      module ChangeContractPeriodWizard
        class NoPartnershipsStep < Step
          def previous_step = :select_contract_period
        end
      end
    end
  end
end
