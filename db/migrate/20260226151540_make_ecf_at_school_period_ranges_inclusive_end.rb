class MakeECFAtSchoolPeriodRangesInclusiveEnd < ActiveRecord::Migration[8.0]
  def change
    # rubocop:disable Rails/BulkChangeTable
    remove_column :ect_at_school_periods, :range, :daterange
    add_column :ect_at_school_periods, :range, :virtual, type: :daterange, as: "daterange(started_on, finished_on, '[]')", stored: true
    # rubocop:enable Rails/BulkChangeTable
  end
end
