class CreateMetadataTeachers < ActiveRecord::Migration[8.0]
  def change
    create_table :metadata_teachers do |t|
      t.references :teacher, null: false, foreign_key: true, index: { unique: true }
      t.date :first_became_eligible_for_ect_training_at, null: true
      t.date :first_became_eligible_for_mentor_training_at, null: true
      t.timestamps
    end
  end
end
