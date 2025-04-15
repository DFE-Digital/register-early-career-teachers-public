class AddRangeToRegistrationPeriod < ActiveRecord::Migration[8.0]
  def change
    add_column :registration_periods, :range, :virtual, type: :daterange, as: "daterange(started_on, finished_on)", stored: true
  end
end
