class CreateActiveLeadProviderBands < ActiveRecord::Migration[8.1]
  def change
    create_table :active_lead_provider_bands do |t|
      t.references :active_lead_provider, foreign_key: true, null: false
      t.integer :allocation_order, null: false
      t.integer :capacity, null: false
      t.timestamps
    end

    add_index :active_lead_provider_bands,
              %i[active_lead_provider_id allocation_order],
              unique: true

    add_reference :contract_banded_fee_structure_bands,
                  :band,
                  null: true,
                  foreign_key: { to_table: :active_lead_provider_bands }

    add_index :contract_banded_fee_structure_bands,
              %i[banded_fee_structure_id band_id],
              unique: true
  end
end
