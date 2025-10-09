class AddRemovedAtToECTAtSchoolPeriods < ActiveRecord::Migration[8.0]
  def change
    add_column :ect_at_school_periods, :removed_at, :datetime
    add_column :ect_at_school_periods, :removed_reason, :string
  end
end
