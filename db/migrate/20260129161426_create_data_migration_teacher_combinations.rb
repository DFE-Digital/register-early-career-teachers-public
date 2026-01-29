class CreateDataMigrationTeacherCombinations < ActiveRecord::Migration[8.0]
  def change
    create_table :data_migration_teacher_combinations do |t|
      t.string "trn"
      t.uuid "participant_id"
      t.jsonb "ecf1_ect_combinations"
      t.jsonb "ecf1_mentor_combinations"
      t.jsonb "ecf2_ect_combinations"
      t.jsonb "ecf2_mentor_combinations"
      t.virtual "ecf1_ect_combinations_count", type: :integer, as: "jsonb_array_length(ecf1_ect_combinations)", stored: true
      t.virtual "ecf1_mentor_combinations_count", type: :integer, as: "jsonb_array_length(ecf1_mentor_combinations)", stored: true
      t.virtual "ecf2_ect_combinations_count", type: :integer, as: "jsonb_array_length(ecf2_ect_combinations)", stored: true
      t.virtual "ecf2_mentor_combinations_count", type: :integer, as: "jsonb_array_length(ecf2_mentor_combinations)", stored: true
      t.timestamps
    end
  end
end
