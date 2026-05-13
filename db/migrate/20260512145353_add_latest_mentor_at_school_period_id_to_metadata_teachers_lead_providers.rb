class AddLatestMentorAtSchoolPeriodIdToMetadataTeachersLeadProviders < ActiveRecord::Migration[8.1]
  def change
    add_column :metadata_teachers_lead_providers, :latest_mentor_at_school_period_id, :bigint, null: true
    add_index :metadata_teachers_lead_providers, :latest_mentor_at_school_period_id
  end
end
