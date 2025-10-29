class AddLatestContractPeriodsToMetadataTeachersLeadProviders < ActiveRecord::Migration[8.0]
  def change
    add_column :metadata_teachers_lead_providers, :latest_ect_contract_period_year, :integer
    add_foreign_key :metadata_teachers_lead_providers,
                    :contract_periods,
                    column: :latest_ect_contract_period_year,
                    primary_key: :year

    add_column :metadata_teachers_lead_providers, :latest_mentor_contract_period_year, :integer
    add_foreign_key :metadata_teachers_lead_providers,
                    :contract_periods,
                    column: :latest_mentor_contract_period_year,
                    primary_key: :year
  end
end
