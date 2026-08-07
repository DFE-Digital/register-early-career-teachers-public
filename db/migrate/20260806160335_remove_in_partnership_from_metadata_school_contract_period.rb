class RemoveInPartnershipFromMetadataSchoolContractPeriod < ActiveRecord::Migration[8.1]
  def change
    remove_column :metadata_schools_contract_periods, :in_partnership, :boolean, null: false
  end
end
