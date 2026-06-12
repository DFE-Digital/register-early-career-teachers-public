class CreateContractBandCapacities < ActiveRecord::Migration[8.1]
  def change
    create_table :contract_band_capacities do |t|
      t.references :active_lead_provider, foreign_key: true
      t.integer :min_declarations, null: false, default: 1
      t.integer :max_declarations, null: false
      t.timestamps
    end

    add_reference :contract_banded_fee_structure_bands,
                  :contract_band_capacity,
                  null: true,
                  foreign_key: true
  end
end
