module Admin
  module Teachers
    module TrainingPeriods
      module ChangeContractPeriodWizard
        class SelectContractPeriodStep < Step
          attribute :contract_period_year, :integer

          validates :contract_period_year, presence: { message: "Select a new contract period" }
          validate :contract_period_available

          def self.permitted_params = %i[contract_period_year]

          def next_step = :select_partnership

        private

          def persist
            value = step_params["contract_period_year"] || contract_period_year
            store.contract_period_year = value
            store.school_partnership_id = nil
          end

          def contract_period_available
            return if contract_period_year.blank?
            return if wizard.contract_periods.where(year: contract_period_year).exists?

            errors.add(:contract_period_year, "Select a new contract period")
          end
        end
      end
    end
  end
end
