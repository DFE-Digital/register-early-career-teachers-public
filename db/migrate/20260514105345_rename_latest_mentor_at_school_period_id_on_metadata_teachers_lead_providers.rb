class RenameLatestMentorAtSchoolPeriodIdOnMetadataTeachersLeadProviders < ActiveRecord::Migration[8.1]
  def change
    rename_column :metadata_teachers_lead_providers,
                  :latest_mentor_at_school_period_id,
                  :ect_assigned_mentor_latest_school_period_id
  end
end
