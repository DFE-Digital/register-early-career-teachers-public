class CreateMetadataTeacherLeadProviders < ActiveRecord::Migration[8.0]
  def change
    create_table :metadata_teacher_lead_providers do |t|
      t.references :teacher, foreign_key: true
      t.references :lead_provider, foreign_key: true

      t.references :latest_ect_training_period, foreign_key: {to_table: :training_periods, on_delete: :nullify}, null: true
      t.references :latest_mentor_training_period, foreign_key: {to_table: :training_periods, on_delete: :nullify}, null: true

      t.timestamps
    end
  end
end
