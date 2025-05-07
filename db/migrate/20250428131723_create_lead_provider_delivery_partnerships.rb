class CreateLeadProviderDeliveryPartnerships < ActiveRecord::Migration[8.0]
  def change
    create_table :lead_provider_delivery_partnerships do |t|
      t.references :lead_provider_active_period, null: false, foreign_key: true
      t.references :delivery_partner, null: false, foreign_key: true

      t.timestamps
    end
  end
end
