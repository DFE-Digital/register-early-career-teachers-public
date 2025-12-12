class RemoveInductionEligibilityFromGIASSchools < ActiveRecord::Migration[8.0]
  def change
    remove_column :gias_schools, :induction_eligibility, :boolean, null: false
  end
end
