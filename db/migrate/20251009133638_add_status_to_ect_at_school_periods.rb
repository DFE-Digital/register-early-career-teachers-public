class AddStatusToECTAtSchoolPeriods < ActiveRecord::Migration[8.0]
  def change
    add_column :ect_at_school_periods, :status, :string, default: "active"
    add_column :ect_at_school_periods, :withdrawn_at, :datetime
  end
end
