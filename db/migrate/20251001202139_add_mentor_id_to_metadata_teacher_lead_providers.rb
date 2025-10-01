class AddMentorIdToMetadataTeacherLeadProviders < ActiveRecord::Migration[8.0]
  def change
    add_column :metadata_teacher_lead_providers, :mentor_id, :uuid
    add_index :metadata_teacher_lead_providers, :mentor_id
  end
end
