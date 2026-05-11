class MakeTrainingPeriodRangesInclusiveEnd < ActiveRecord::Migration[8.1]
  def change
    # rubocop:disable Rails/BulkChangeTable
    remove_column :training_periods, :range, :daterange
    add_column :training_periods, :range, :virtual, type: :daterange, as: "daterange(started_on, finished_on, '[]')", stored: true
    # rubocop:enable Rails/BulkChangeTable
  end
end
