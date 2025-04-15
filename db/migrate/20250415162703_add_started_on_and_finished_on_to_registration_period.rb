class AddStartedOnAndFinishedOnToRegistrationPeriod < ActiveRecord::Migration[8.0]
  def change
    change_table(:registration_periods, bulk: true) do |t|
      t.column :started_on, :date
      t.column :finished_on, :date
      t.column :enabled, :boolean, default: false
    end
  end
end
