class CreateTeacherMigrationFailure < ActiveRecord::Migration[8.0]
  def change
    create_table :teacher_migration_failures do |t|
      t.references :teacher, foreign_key: true
      t.string :message, null: false
      t.uuid :migration_item_id, null: true
      t.string :migration_item_type, null: true

      t.timestamps
    end
  end
end
