class AddUniqueIndexToLeadProviderDeliveryPartnerships < ActiveRecord::Migration[8.0]
  def change
    add_index :lead_provider_delivery_partnerships, %i[lead_provider_active_period_id delivery_partner_id], unique: true
  end
end
