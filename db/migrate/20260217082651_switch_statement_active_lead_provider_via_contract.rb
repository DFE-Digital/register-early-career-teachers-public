class SwitchStatementActiveLeadProviderViaContract < ActiveRecord::Migration[8.0]
  def change
    # Require contract on statement.
    change_column_null :statements, :contract_id, false
    # Require active_lead_provider on contract.
    change_column_null :contracts, :active_lead_provider_id, false
    # Remove active_lead_provider from statement.
    remove_reference :statements, :active_lead_provider, index: true, foreign_key: true, null: false
  end
end
