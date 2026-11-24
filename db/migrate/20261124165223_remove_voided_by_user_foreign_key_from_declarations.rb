class RemoveVoidedByUserForeignKeyFromDeclarations < ActiveRecord::Migration[8.1]
  def up
    remove_foreign_key :declarations, :users, column: :voided_by_user_id
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "Deleted users may still be referenced by legacy declaration columns"
  end
end
