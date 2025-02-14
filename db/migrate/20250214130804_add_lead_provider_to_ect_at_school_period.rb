class AddLeadProviderToECTAtSchoolPeriod < ActiveRecord::Migration[8.0]
  def change
    add_reference :ect_at_school_periods, :lead_provider, foreign_key: true
  end
end
