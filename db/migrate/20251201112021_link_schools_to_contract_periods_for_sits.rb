class LinkSchoolsToContractPeriodsForSits < ActiveRecord::Migration[8.0]
  def change
    add_column :schools, :induction_tutor_last_nominated_in_year, :integer, null: true
    add_foreign_key "schools", "contract_periods", column: "induction_tutor_last_nominated_in_year", primary_key: "year"
  end
end
