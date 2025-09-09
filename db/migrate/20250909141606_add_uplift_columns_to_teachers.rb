class AddUpliftColumnsToTeachers < ActiveRecord::Migration[8.0]
  def change
    add_column :teachers, :ect_sparsity_uplift, :boolean, default: false, null: false
    add_column :teachers, :ect_pupil_premium_uplift, :boolean, default: false, null: false
  end
end
