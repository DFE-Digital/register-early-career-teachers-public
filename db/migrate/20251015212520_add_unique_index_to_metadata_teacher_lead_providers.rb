class AddUniqueIndexToMetadataTeacherLeadProviders < ActiveRecord::Migration[8.0]
  def change
    add_index :metadata_teachers_lead_providers, %i[teacher_id lead_provider_id], unique: true
  end
end
