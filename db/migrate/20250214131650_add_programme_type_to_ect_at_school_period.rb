class AddProgrammeTypeToECTAtSchoolPeriod < ActiveRecord::Migration[8.0]
  def change
    add_column :ect_at_school_periods, :programme_type, :string
  end
end
