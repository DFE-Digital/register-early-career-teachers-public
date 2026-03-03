class AddMigrationModeToCombinations < ActiveRecord::Migration[8.0]
  def change
    add_column :data_migration_teacher_combinations, :migration_mode, :string
  end
end
