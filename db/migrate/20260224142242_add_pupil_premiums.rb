class AddPupilPremiums < ActiveRecord::Migration[8.0]
  def change
    create_table :pupil_premiums do |t|
      t.bigint :school_urn, null: false
      t.integer :contract_period_year, null: false

      t.boolean :pupil_premium_uplift, null: false, default: false
      t.boolean :sparsity_uplift, null: false, default: false

      t.timestamps
    end

    add_foreign_key :pupil_premiums, :schools,
                    column: :school_urn,
                    primary_key: :urn

    add_foreign_key :pupil_premiums, :contract_periods,
                    column: :contract_period_year,
                    primary_key: :year

    add_index :pupil_premiums, :school_urn
    add_index :pupil_premiums, :contract_period_year
  end
end
