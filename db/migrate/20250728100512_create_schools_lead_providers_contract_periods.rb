class CreateSchoolsLeadProvidersContractPeriods < ActiveRecord::Migration[8.0]
  def change
    create_view :schools_lead_providers_contract_periods
  end
end
