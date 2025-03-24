class CreatePendingInductionSubmissionBatches < ActiveRecord::Migration[8.0]
  def change
    create_enum :batch_status, %w[pending processing completed failed]

    create_table :pending_induction_submission_batches do |t|
      t.references :appropriate_body, null: false, foreign_key: true
      t.string :error_message
      t.enum :status, enum_type: :batch_status, default: 'pending', null: false
      t.timestamps
    end

    add_reference :pending_induction_submissions, :pending_induction_submission_batch, foreign_key: true
    add_column :pending_induction_submissions, :error_message, :string
  end
end
