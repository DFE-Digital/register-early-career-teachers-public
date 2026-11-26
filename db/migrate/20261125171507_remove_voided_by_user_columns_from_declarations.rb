class RemoveVoidedByUserColumnsFromDeclarations < ActiveRecord::Migration[8.1]
  def up
    remove_columns :declarations, :voided_by_user_id, :voided_by_user_at
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
