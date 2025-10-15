class AddScheduleIdToTrainingPeriods < ActiveRecord::Migration[8.0]
  def change
    add_reference :training_periods, :schedule, foreign_key: true, index: true
  end
end
