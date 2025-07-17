class AddAPIUpdatedAtToSchools < ActiveRecord::Migration[8.0]
  def change
    add_column :schools, :api_updated_at, :datetime, default: -> { "CURRENT_TIMESTAMP" }
  end
end
