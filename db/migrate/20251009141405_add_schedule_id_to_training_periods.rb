class AddScheduleIdToTrainingPeriods < ActiveRecord::Migration[8.0]
  def change
    # rubocop:disable Rails/NotNullColumn
    add_reference :training_periods, :schedule, foreign_key: true, index: true, null: false
    # rubocop:enable Rails/NotNullColumn
  end
end
