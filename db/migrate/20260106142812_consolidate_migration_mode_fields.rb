class ConsolidateMigrationModeFields < ActiveRecord::Migration[8.0]
  def change
    remove_column :teachers, :ect_migration_mode, default: "not_migrated", enum_type: "participant_migration_mode"
    rename_column :teachers, :mentor_migration_mode, :migration_mode
  end
end
