class AddCompletingBatchStatus < ActiveRecord::Migration[8.0]
  # Not reversible
  def change
    add_enum_value :batch_status, "completing", before: "completed"
  end
end
