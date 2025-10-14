class AddTrnlessFlagToTeachers < ActiveRecord::Migration[8.0]
  def up
    # rubocop:disable Rails/BulkChangeTable
    add_column :teachers, :trnless, :boolean, null: false, default: false
    change_column :teachers, :trn, :varchar, null: true
    add_check_constraint :teachers, "trnless or (trn is not null)", name: :check_trn_presence
    # rubocop:enable Rails/BulkChangeTable
  end

  def down
    remove_column :trnless, :boolean, null: false, default: false
  end
end
