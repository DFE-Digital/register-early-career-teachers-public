class AllowNilNameOnAppropriateBodyPeriods < ActiveRecord::Migration[8.1]
  def change
    change_column_null :appropriate_body_periods, :name, true
  end
end
