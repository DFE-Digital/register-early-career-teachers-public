class CreateSchedules < ActiveRecord::Migration[8.0]
  def change
    create_table :schedules do |t|
      t.integer "contract_period_year", null: false
      t.enum "identifier", null: false, enum_type: "schedule_identifiers"
      t.timestamps
    end

    add_foreign_key "schedules", "contract_periods", column: "contract_period_year", primary_key: "year"
    add_index :schedules, %i[contract_period_year identifier], unique: true
  end
end
