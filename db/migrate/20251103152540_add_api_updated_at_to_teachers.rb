class AddAPIUpdatedAtToTeachers < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_column :teachers, :api_updated_at, :datetime, default: -> { "CURRENT_TIMESTAMP" }
    add_index :teachers, :api_updated_at, algorithm: :concurrently
  end
end
