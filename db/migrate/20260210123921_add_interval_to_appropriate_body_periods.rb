class AddIntervalToAppropriateBodyPeriods < ActiveRecord::Migration[8.0]
  def change
    change_table :appropriate_body_periods, bulk: true do |t|
      t.date :started_on # TODO: add started_on values to appropriate_body_periods and enforce
      t.date :finished_on
      t.virtual :range, type: :daterange, as: "daterange(started_on, finished_on)", stored: true
    end
  end
end
