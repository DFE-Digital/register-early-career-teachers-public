class AddVATRateToContracts < ActiveRecord::Migration[8.0]
  def change
    add_column :contracts, :vat_rate, :decimal, precision: 3, scale: 2, default: 0.2, null: false
  end
end
