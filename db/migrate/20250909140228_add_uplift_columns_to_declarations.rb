class AddUpliftColumnsToDeclarations < ActiveRecord::Migration[8.0]
  def change
    add_column :declarations, :pupil_premium_uplift, :boolean
    add_column :declarations, :sparsity_uplift, :boolean
  end
end
