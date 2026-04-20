class SwitchNotNullFromMetadataSchoolsContractPeriods < ActiveRecord::Migration[8.0]
  def change
    change_column_null :metadata_schools_contract_periods, :contract_period_year, false
  end
end
