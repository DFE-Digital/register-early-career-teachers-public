class AddAPIMentorIdToMetadataTeachersLeadProviders < ActiveRecord::Migration[8.0]
  def change
    add_column :metadata_teachers_lead_providers, :api_mentor_id, :uuid
  end
end
