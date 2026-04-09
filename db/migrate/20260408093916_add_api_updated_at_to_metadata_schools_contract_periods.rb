class AddAPIUpdatedAtToMetadataSchoolsContractPeriods < ActiveRecord::Migration[8.0]
  def change
    add_column :metadata_schools_contract_periods, :api_updated_at, :datetime, default: -> { "CURRENT_TIMESTAMP" }
  end
end
