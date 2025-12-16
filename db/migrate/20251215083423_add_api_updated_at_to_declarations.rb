class AddAPIUpdatedAtToDeclarations < ActiveRecord::Migration[8.0]
  def change
    add_column :declarations, :api_updated_at, :datetime, default: -> { "CURRENT_TIMESTAMP" }
  end
end
