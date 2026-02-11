class AddMentorshipFieldsToDataMigrationTeacherCombinationsTable < ActiveRecord::Migration[8.0]
  def up
    change_table :data_migration_teacher_combinations, bulk: true do |t|
      t.jsonb :ecf1_mentorships, default: [], null: false
      t.jsonb :ecf2_mentorships, default: [], null: false
      t.virtual :ecf1_mentorships_count, type: :integer, as: "jsonb_array_length(ecf1_mentorships)", stored: true
      t.virtual :ecf2_mentorships_count, type: :integer, as: "jsonb_array_length(ecf2_mentorships)", stored: true
    end
  end

  def down
    change_table :data_migration_teacher_combinations, bulk: true do |t|
      t.remove :ecf2_mentorships_count
      t.remove :ecf1_mentorships_count
      t.remove :ecf2_mentorships
      t.remove :ecf1_mentorships
    end
  end
end
