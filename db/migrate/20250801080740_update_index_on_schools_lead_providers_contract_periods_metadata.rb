class UpdateIndexOnSchoolsLeadProvidersContractPeriodsMetadata < ActiveRecord::Migration[8.0]
  def change
    remove_index :schools_lead_providers_contract_periods_metadata, column: %i[school_id contract_period_id], unique: true

    add_index :schools_lead_providers_contract_periods_metadata,
              %i[school_id contract_period_id lead_provider_id],
              unique: true,
              name: 'index_schools_lead_providers_on_school_contract_lead'
  end
end
