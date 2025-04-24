class RenameProviderPartnershipsToSchoolPartnerships < ActiveRecord::Migration[8.0]
  def change
    rename_table :provider_partnerships, :school_partnerships

    rename_column :training_periods, :provider_partnership_id, :school_partnership_id
    rename_column :events, :provider_partnership_id, :school_partnership_id
  end
end
