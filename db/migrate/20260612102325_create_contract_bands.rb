class CreateContractBands < ActiveRecord::Migration[8.1]
  def change
    create_table :contract_bands do |t|
      t.references :active_lead_provider, foreign_key: true, null: false
      t.integer :allocation_order, null: false
      t.integer :capacity, null: false
      t.timestamps
    end

    add_index :contract_bands,
              %i[active_lead_provider_id allocation_order],
              unique: true

    add_reference :contract_banded_fee_structure_bands,
                  :contract_band,
                  null: true,
                  foreign_key: { to_table: :contract_bands }

    add_index :contract_banded_fee_structure_bands,
              %i[banded_fee_structure_id contract_band_id],
              unique: true
  end
end
