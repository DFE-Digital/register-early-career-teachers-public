class RenameSchoolKeysOnAppropriateBodyPeriodsAndRegionAwards < ActiveRecord::Migration[8.1]
  def change
    rename_column :appropriate_body_periods, :school_id, :provisioning_school_id
    rename_column :region_awards, :school_id, :lead_school_id
  end
end
