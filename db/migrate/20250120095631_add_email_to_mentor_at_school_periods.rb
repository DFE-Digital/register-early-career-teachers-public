class AddEmailToMentorAtSchoolPeriods < ActiveRecord::Migration[8.0]
  def change
    add_column :mentor_at_school_periods, :email, :string
  end
end
