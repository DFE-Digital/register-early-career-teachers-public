class AddECFIdToLeadProviderDeliveryPartnerships < ActiveRecord::Migration[8.0]
  def change
    add_column :lead_provider_delivery_partnerships, :ecf_id, :uuid, null: true
    add_index :lead_provider_delivery_partnerships, :ecf_id, unique: true
  end
end
