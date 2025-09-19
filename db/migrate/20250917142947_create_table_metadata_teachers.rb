class CreateTableMetadataTeachers < ActiveRecord::Migration[8.0]
  def change
    create_table :metadata_teachers do |t|
      t.references :teacher, null: false, foreign_key: true, index: { unique: true }
      t.date :induction_started_on, null: true
      t.date :induction_finished_on, null: true
      t.timestamps
    end
  end
end
