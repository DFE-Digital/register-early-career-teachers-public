class CreateAvailableProviderPairings < ActiveRecord::Migration[8.0]
  def change
    create_table :available_provider_pairings do |t|
      t.references :active_lead_provider, null: false
      t.references :delivery_partner, null: false
      t.index %i[active_lead_provider_id delivery_partner_id], unique: true
      t.timestamps
    end
  end
end
