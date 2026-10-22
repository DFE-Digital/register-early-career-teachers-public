class AddIntervalToAppropriateBodyPeriods < ActiveRecord::Migration[8.1]
  def change
    change_table :appropriate_body_periods, bulk: true do |t|
      t.date :started_on
      t.date :finished_on
      t.virtual :range, type: :daterange, as: "daterange(started_on, finished_on, '[]')", stored: true
    end

    add_check_constraint :appropriate_body_periods, "finished_on >= started_on",
                         name: "finished_on_not_before_started_on"
  end
end
