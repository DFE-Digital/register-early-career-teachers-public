class AddSupersededByToDeclarations < ActiveRecord::Migration[8.0]
  def change
    add_reference :declarations, :superseded_by, null: true, foreign_key: { to_table: :declarations }, index: true
  end
end
