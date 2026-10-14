class AddDeclarationsInSequenceEnabledToContractPeriods < ActiveRecord::Migration[8.0]
  def up
    add_column :contract_periods, :declarations_in_sequence_enabled, :boolean, default: true, null: false

    ContractPeriod.where("year < 2025").update_all(declarations_in_sequence_enabled: false)
  end

  def down
    remove_column :contract_periods, :declarations_in_sequence_enabled
  end
end
