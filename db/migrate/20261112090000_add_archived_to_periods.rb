class AddArchivedToPeriods < ActiveRecord::Migration[8.1]
  def change
    %i[
      training_periods
      ect_at_school_periods
      mentor_at_school_periods
      mentorship_periods
    ].each do |table|
      add_column table, :archived, :boolean, default: false, null: false
    end
  end
end
