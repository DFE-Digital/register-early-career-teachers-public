class AddUpliftFeesEnabledToContractPeriods < ActiveRecord::Migration[8.0]
  def up
    add_column :contract_periods, :uplift_fees_enabled, :boolean, default: true, null: false

    ContractPeriod.where("year >= 2025").update_all(uplift_fees_enabled: false)
  end

  def down
    remove_column :contract_periods, :uplift_fees_enabled
  end
end
