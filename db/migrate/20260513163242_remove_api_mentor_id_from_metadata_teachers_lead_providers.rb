class RemoveAPIMentorIdFromMetadataTeachersLeadProviders < ActiveRecord::Migration[8.1]
  def change
    remove_column :metadata_teachers_lead_providers, :api_mentor_id, :uuid
  end
end
