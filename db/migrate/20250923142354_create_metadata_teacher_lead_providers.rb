class CreateMetadataTeacherLeadProviders < ActiveRecord::Migration[8.0]
  def change
    create_table :metadata_teacher_lead_providers do |t|
      t.references :teacher, foreign_key: true
      t.references :lead_provider, foreign_key: true
      t.datetime :ect_training_record_created_at
      t.datetime :mentor_training_record_created_at

      t.timestamps
    end
  end
end
