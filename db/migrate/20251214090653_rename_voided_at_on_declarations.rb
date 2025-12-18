class RenameVoidedAtOnDeclarations < ActiveRecord::Migration[8.0]
  def change
    rename_column :declarations, :voided_at, :voided_by_user_at
  end
end
