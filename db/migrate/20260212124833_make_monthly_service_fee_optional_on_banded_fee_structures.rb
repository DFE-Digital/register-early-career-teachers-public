class MakeMonthlyServiceFeeOptionalOnBandedFeeStructures < ActiveRecord::Migration[8.0]
  def change
    change_column_null :contract_banded_fee_structures, :monthly_service_fee, true
  end
end
