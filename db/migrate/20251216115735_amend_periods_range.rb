class AmendPeriodsRange < ActiveRecord::Migration[8.0]
  def change
    remove_column :ect_at_school_periods, :range, :daterange
    remove_column :induction_periods, :range, :daterange
    remove_column :mentor_at_school_periods, :range, :daterange
    remove_column :mentorship_periods, :range, :daterange
    remove_column :training_periods, :range, :daterange
    remove_column :contract_periods, :range, :daterange

    add_column :ect_at_school_periods, :range, :virtual, type: :daterange, as: "daterange(started_on, finished_on, '[]')", stored: true
    add_column :induction_periods, :range, :virtual, type: :daterange, as: "daterange(started_on, finished_on, '[]')", stored: true
    add_column :mentor_at_school_periods, :range, :virtual, type: :daterange, as: "daterange(started_on, finished_on, '[]')", stored: true
    add_column :mentorship_periods, :range, :virtual, type: :daterange, as: "daterange(started_on, finished_on, '[]')", stored: true
    add_column :training_periods, :range, :virtual, type: :daterange, as: "daterange(started_on, finished_on, '[]')", stored: true
    add_column :contract_periods, :range, :virtual, type: :daterange, as: "daterange(started_on, finished_on, '[]')", stored: true
  end
end
