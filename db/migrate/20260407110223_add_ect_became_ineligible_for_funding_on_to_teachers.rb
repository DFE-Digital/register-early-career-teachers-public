class AddECTBecameIneligibleForFundingOnToTeachers < ActiveRecord::Migration[8.0]
  def change
    add_column :teachers, :ect_became_ineligible_for_funding_on, :date
  end
end
