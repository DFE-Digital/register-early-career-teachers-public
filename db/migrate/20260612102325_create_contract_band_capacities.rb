class CreateContractBandCapacities < ActiveRecord::Migration[8.1]
  def change
    create_table :contract_band_capacities do |t|
      t.references :active_lead_provider, foreign_key: true, null: false
      t.integer :min_declarations, null: false, default: 1
      t.integer :max_declarations, null: false
      t.timestamps
    end

    add_index :contract_band_capacities,
              %i[active_lead_provider_id min_declarations],
              unique: true

    add_reference :contract_banded_fee_structure_bands,
                  :contract_band_capacity,
                  null: true,
                  foreign_key: { to_table: :contract_band_capacities }

    add_index :contract_banded_fee_structure_bands,
              %i[banded_fee_structure_id contract_band_capacity_id],
              unique: true
  end
end
