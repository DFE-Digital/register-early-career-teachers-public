class AddEmailToECTAtSchoolPeriods < ActiveRecord::Migration[8.0]
  def change
    add_column :ect_at_school_periods, :email, :string
  end
end
