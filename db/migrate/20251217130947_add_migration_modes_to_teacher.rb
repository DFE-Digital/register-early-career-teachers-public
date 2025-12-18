class AddMigrationModesToTeacher < ActiveRecord::Migration[8.0]
  def change
    create_enum :participant_migration_mode, %w[latest_induction_records all_induction_records not_migrated]

    change_table :teachers, bulk: true do |t|
      t.enum :ect_migration_mode, enum_type: :participant_migration_mode, default: "not_migrated"
      t.enum :mentor_migration_mode, enum_type: :participant_migration_mode, default: "not_migrated"
    end
  end
end
