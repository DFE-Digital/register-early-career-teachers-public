class AddPaymentsFrozenYearsToTeacher < ActiveRecord::Migration[8.0]
  def change
    change_table :teachers, bulk: true do |t|
      t.integer :ect_payments_frozen_year, null: true
      t.integer :mentor_payments_frozen_year, null: true

      t.foreign_key :contract_periods, column: :ect_payments_frozen_year, primary_key: :year
      t.foreign_key :contract_periods, column: :mentor_payments_frozen_year, primary_key: :year
    end
  end
end
