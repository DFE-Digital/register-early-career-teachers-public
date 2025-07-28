class AddAPIUpdatedAtToDeliveryPartners < ActiveRecord::Migration[8.0]
  def change
    add_column :delivery_partners, :api_updated_at, :datetime, default: -> { "CURRENT_TIMESTAMP" }
  end
end
