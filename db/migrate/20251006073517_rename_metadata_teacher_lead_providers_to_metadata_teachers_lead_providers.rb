class RenameMetadataTeacherLeadProvidersToMetadataTeachersLeadProviders < ActiveRecord::Migration[8.0]
  def change
    rename_table :metadata_teacher_lead_providers, :metadata_teachers_lead_providers
  end
end
