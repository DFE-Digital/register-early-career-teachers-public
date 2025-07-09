class RemoveLeadProviderIdFromECTAtSchoolPeriods < ActiveRecord::Migration[8.0]
  def change
    remove_reference :ect_at_school_periods, :lead_provider, foreign_key: true, index: true
  end
end
