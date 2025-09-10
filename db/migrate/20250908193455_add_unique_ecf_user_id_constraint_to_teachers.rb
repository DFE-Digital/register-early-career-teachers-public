class AddUniqueECFUserIdConstraintToTeachers < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def up
    add_index :teachers, :ecf_user_id, unique: true, algorithm: :concurrently
  end

  def down
    remove_index :teachers, :ecf_user_id
  end
end
