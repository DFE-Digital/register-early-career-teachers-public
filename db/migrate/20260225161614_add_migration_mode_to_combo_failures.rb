class AddMigrationModeToComboFailures < ActiveRecord::Migration[8.0]
  def change
    add_column :data_migration_failed_combinations, :migration_mode, :string
    add_column :data_migration_failed_mentorships, :migration_mode, :string
  end
end
