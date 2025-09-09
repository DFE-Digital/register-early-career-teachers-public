class AddUpliftColumnsToECTAtSchoolPeriods < ActiveRecord::Migration[8.0]
  def change
    add_column :ect_at_school_periods, :sparsity_uplift, :boolean, default: false, null: false
    add_column :ect_at_school_periods, :pupil_premium_uplift, :boolean, default: false, null: false
  end
end
