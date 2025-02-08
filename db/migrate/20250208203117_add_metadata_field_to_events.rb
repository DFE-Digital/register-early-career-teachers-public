class AddMetadataFieldToEvents < ActiveRecord::Migration[8.0]
  def change
    add_column :events, :metadata, :jsonb
  end
end
