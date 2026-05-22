class AddContractPeriodToEvents < ActiveRecord::Migration[8.1]
  def change
    add_reference :events, :contract_period, index: true, null: true, foreign_key: { primary_key: :year, on_delete: :nullify }
  end
end
