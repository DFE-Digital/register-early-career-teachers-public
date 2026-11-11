class AddNotNullToAppropriateBodyPeriodStartedOn < ActiveRecord::Migration[8.1]
  def change
    change_column_null :appropriate_body_periods, :started_on, false
  end
end
