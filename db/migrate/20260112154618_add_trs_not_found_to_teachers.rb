class AddTRSNotFoundToTeachers < ActiveRecord::Migration[8.0]
  def change
    add_column :teachers, :trs_not_found, :boolean, null: true, default: false
  end
end
