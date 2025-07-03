class RenameRegistrationPeriodsToContractPeriods < ActiveRecord::Migration[8.0]
  def change
    rename_table :registration_periods, :contract_periods
    rename_column :active_lead_providers, :registration_period_id, :contract_period_id
  end
end
