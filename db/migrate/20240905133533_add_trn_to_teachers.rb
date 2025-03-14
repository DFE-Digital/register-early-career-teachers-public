class AddTRNToTeachers < ActiveRecord::Migration[7.2]
  def change
    add_column :teachers, :trn, :string, null: false
    add_index :teachers, :trn, unique: true
  end
end
