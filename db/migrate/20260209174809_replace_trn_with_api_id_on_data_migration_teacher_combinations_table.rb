class ReplaceTRNWithAPIIdOnDataMigrationTeacherCombinationsTable < ActiveRecord::Migration[8.0]
  def change
    change_table :data_migration_teacher_combinations, bulk: true do |t|
      t.remove :trn, type: :string
      t.uuid :api_id
    end
  end
end
