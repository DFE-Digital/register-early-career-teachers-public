class AddWithdrawnByErrorFlagToECTAndMentorAtSchoolPeriods < ActiveRecord::Migration[8.0]
  def change
    add_column :ect_at_school_periods, :withdrawn_by_error, :boolean, default: false, null: false
    add_column :mentor_at_school_periods, :withdrawn_by_error, :boolean, default: false, null: false
    add_index :ect_at_school_periods, :withdrawn_by_error
    add_index :mentor_at_school_periods, :withdrawn_by_error
  end
end
