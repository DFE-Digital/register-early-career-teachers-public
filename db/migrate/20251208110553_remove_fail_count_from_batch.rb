class RemoveFailCountFromBatch < ActiveRecord::Migration[8.0]
  def change
     remove_column :pending_induction_submission_batchs, :failed_count, :integer
  end
end
