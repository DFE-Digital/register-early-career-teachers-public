class AddAppropriateBodyToECTAtSchoolPeriod < ActiveRecord::Migration[8.0]
  def change
    add_reference :ect_at_school_periods, :appropriate_body, foreign_key: true
  end
end
