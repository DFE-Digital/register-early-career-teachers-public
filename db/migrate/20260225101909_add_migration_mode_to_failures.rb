class AddMigrationModeToFailures < ActiveRecord::Migration[8.0]
  def change
    add_column :migration_failures, :migration_mode, :string
    add_column :teacher_migration_failures, :migration_mode, :string
  end
end
