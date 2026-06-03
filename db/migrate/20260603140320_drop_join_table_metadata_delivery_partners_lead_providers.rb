class DropJoinTableMetadataDeliveryPartnersLeadProviders < ActiveRecord::Migration[8.1]
  def change
    drop_table :metadata_delivery_partners_lead_providers do |t|
      t.references :delivery_partner, null: false, foreign_key: true, index: true
      t.references :lead_provider, null: false, foreign_key: true, index: true
      t.integer :contract_period_years, array: true, null: false, default: []

      t.timestamps

      t.index %i[delivery_partner_id lead_provider_id],
              unique: true,
              name: "idx_on_delivery_partner_id_lead_provider_id_a83df5ed0c"
    end
  end
end
