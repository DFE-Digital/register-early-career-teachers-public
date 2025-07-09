class AddMetricsToPendingInductionSubmissionBatch < ActiveRecord::Migration[8.0]
  def change
    change_table :pending_induction_submission_batches, bulk: true do |t|
      t.integer :uploaded_count
      t.integer :processed_count
      t.integer :errored_count
      t.integer :released_count
      t.integer :failed_count
      t.integer :passed_count
      t.integer :claimed_count
      t.integer :file_size
      t.string :file_type
    end

    rename_column :pending_induction_submission_batches, :filename, :file_name
  end
end
