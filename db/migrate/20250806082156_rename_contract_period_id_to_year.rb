class RenameContractPeriodIdToYear < ActiveRecord::Migration[8.0]
  def change
    rename_column :active_lead_providers, :contract_period_year, :contract_period_year
  end
end
