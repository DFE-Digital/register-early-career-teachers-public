class CreateJoinTableMetadataSchoolsLeadProvidersContractPeriods < ActiveRecord::Migration[8.0]
  def change
    create_table :metadata_schools_lead_providers_contract_periods do |t|
      t.references :school, null: false, foreign_key: true, index: true
      t.references :lead_provider, null: false, foreign_key: true, index: true
      t.integer :contract_period_year, index: true
      t.boolean :expression_of_interest, null: false
      t.timestamps
    end

    add_foreign_key :metadata_schools_lead_providers_contract_periods, :contract_periods, column: :contract_period_year, primary_key: :year
    add_index :metadata_schools_lead_providers_contract_periods, %i[school_id lead_provider_id contract_period_year], unique: true
  end
end
