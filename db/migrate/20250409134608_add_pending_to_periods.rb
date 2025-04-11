class AddPendingToPeriods < ActiveRecord::Migration[8.0]
  def change
    add_column :ect_at_school_periods, :pending, :boolean, default: false
    add_column :mentor_at_school_periods, :pending, :boolean, default: false
    add_column :mentorship_periods, :pending, :boolean, default: false
    add_column :training_periods, :pending, :boolean, default: false
  end
end
