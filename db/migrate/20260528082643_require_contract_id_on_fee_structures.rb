class RequireContractIdOnFeeStructures < ActiveRecord::Migration[8.1]
  def change
    change_column_null :contract_banded_fee_structures, :contract_id, false
    change_column_null :contract_flat_rate_fee_structures, :contract_id, false
  end
end
