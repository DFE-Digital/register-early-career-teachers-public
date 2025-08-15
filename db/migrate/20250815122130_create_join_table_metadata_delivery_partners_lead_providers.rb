class CreateJoinTableMetadataDeliveryPartnersLeadProviders < ActiveRecord::Migration[8.0]
  def change
    create_table :metadata_delivery_partners_lead_providers do |t|
      t.references :delivery_partner, null: false, foreign_key: true, index: true
      t.references :lead_provider, null: false, foreign_key: true, index: true
      t.integer :contract_period_years, array: true, null: false, default: []

      t.timestamps
    end

    add_index :metadata_delivery_partners_lead_providers, %i[delivery_partner_id lead_provider_id], unique: true
  end
end
