class CreateParityCheckRuns < ActiveRecord::Migration[8.0]
  def change
    create_table :parity_check_runs do |t|
      t.datetime :started_at
      t.datetime :completed_at

      t.timestamps
    end
  end
end
