class CreateJoinTableSchoolsLeadProvidersContractPeriodsMetadata < ActiveRecord::Migration[8.0]
  def change
    create_enum :induction_programme_choice, %w[not_yet_known provider_led school_led]

    create_table :schools_lead_providers_contract_periods_metadata do |t|
      t.references :school, null: false, foreign_key: true, index: true
      t.references :lead_provider, null: false, foreign_key: true, index: true
      t.references :contract_period, null: false, foreign_key: { primary_key: :year }, index: true
      t.boolean :in_partnership, null: false
      t.boolean :expression_of_interest, null: false
      t.enum :induction_programme_choice, null: false, enum_type: :induction_programme_choice
      t.timestamps
    end

    add_index :schools_lead_providers_contract_periods_metadata, %i[school_id contract_period_id], unique: true
  end
end
