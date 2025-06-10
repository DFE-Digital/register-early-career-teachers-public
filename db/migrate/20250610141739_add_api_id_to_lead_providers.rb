class AddAPIIdToLeadProviders < ActiveRecord::Migration[8.0]
  def change
    add_column :lead_providers, :api_id, :uuid, null: true
    add_index :lead_providers, :api_id, unique: true
  end
end
