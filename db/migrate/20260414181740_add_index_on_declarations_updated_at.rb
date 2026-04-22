class AddIndexOnDeclarationsUpdatedAt < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_index :declarations, :updated_at, algorithm: :concurrently
  end
end
