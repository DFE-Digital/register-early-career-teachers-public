class CreateJoinTableMetadataSchoolsContractPeriods < ActiveRecord::Migration[8.0]
  def change
    create_enum :induction_programme_choice, %w[not_yet_known provider_led school_led]

    create_table :metadata_schools_contract_periods do |t|
      t.references :school, null: false, foreign_key: true, index: true
      t.integer :contract_period_year, index: true
      t.boolean :in_partnership, null: false
      t.enum :induction_programme_choice, null: false, enum_type: :induction_programme_choice
      t.timestamps
    end

    add_foreign_key :metadata_schools_contract_periods, :contract_periods, column: :contract_period_year, primary_key: :year
    add_index :metadata_schools_contract_periods, %i[school_id contract_period_year], unique: true
  end
end
