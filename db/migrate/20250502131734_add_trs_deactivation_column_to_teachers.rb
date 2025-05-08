class AddTRSDeactivationColumnToTeachers < ActiveRecord::Migration[8.0]
  def change
    add_column :teachers, :trs_deactivated, :boolean, null: true, default: false
  end
end
