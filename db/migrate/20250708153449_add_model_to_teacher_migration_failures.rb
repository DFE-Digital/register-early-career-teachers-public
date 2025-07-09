class AddModelToTeacherMigrationFailures < ActiveRecord::Migration[8.0]
  def change
    add_column :teacher_migration_failures, :model, :string, null: false, default: "teacher"
    add_index :teacher_migration_failures, :model
  end
end
