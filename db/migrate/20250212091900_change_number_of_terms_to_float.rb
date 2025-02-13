class ChangeNumberOfTermsToFloat < ActiveRecord::Migration[8.0]
  def up
    change_column :induction_periods, :number_of_terms, :float
    change_column :pending_induction_submissions, :number_of_terms, :float
    change_column :induction_extensions, :number_of_terms, :float
  end

  def down
    change_column :pending_induction_submissions, :number_of_terms, :decimal, precision: 3, scale: 1
    change_column :induction_periods, :number_of_terms, :decimal, precision: 3, scale: 1
    change_column :induction_extensions, :number_of_terms, :decimal, precision: 3, scale: 1
  end
end
