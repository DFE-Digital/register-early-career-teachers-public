class RenameExpressionOfInterestOnMetadataSchoolsLeadProvidersContractPeriods < ActiveRecord::Migration[8.0]
  def change
    rename_column :metadata_schools_lead_providers_contract_periods, :expression_of_interest, :expression_of_interest_or_school_partnership
  end
end
