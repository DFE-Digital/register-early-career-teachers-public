class RenameAPIIdToECFIdInLeadProviders < ActiveRecord::Migration[8.0]
  def change
    rename_column :lead_providers, :api_id, :ecf_id
  end
end
