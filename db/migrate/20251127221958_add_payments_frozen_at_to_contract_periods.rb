class AddPaymentsFrozenAtToContractPeriods < ActiveRecord::Migration[8.0]
  def change
    add_column :contract_periods, :payments_frozen_at, :datetime
  end
end
