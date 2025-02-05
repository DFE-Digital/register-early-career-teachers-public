class AddDeleteAtTimestampToPendingInductionSubmissions < ActiveRecord::Migration[8.0]
  def change
    add_column :pending_induction_submissions, :delete_at, :timestamp, null: true
  end
end
