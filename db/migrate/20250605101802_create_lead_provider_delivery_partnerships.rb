class CreateLeadProviderDeliveryPartnerships < ActiveRecord::Migration[8.0]
  def change
    create_table :lead_provider_delivery_partnerships do |t|
      t.references :active_lead_provider, null: false
      t.references :delivery_partner, null: false
      t.index %i[active_lead_provider_id delivery_partner_id], unique: true
      t.timestamps
    end
  end
end
