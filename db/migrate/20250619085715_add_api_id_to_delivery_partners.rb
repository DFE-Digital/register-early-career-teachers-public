class AddAPIIdToDeliveryPartners < ActiveRecord::Migration[8.0]
  def change
    add_column :delivery_partners, :api_id, :uuid, default: -> { "gen_random_uuid()" }, null: false
    add_index :delivery_partners, :api_id, unique: true
  end
end
