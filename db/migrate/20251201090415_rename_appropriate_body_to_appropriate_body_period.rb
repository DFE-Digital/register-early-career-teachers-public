class RenameAppropriateBodyToAppropriateBodyPeriod < ActiveRecord::Migration[8.0]
  def change
    rename_table :appropriate_bodies, :appropriate_body_periods

    rename_column :events, :appropriate_body_id, :appropriate_body_period_id
    rename_column :induction_periods, :appropriate_body_id, :appropriate_body_period_id
    rename_column :pending_induction_submissions, :appropriate_body_id, :appropriate_body_period_id
    rename_column :pending_induction_submission_batches, :appropriate_body_id, :appropriate_body_period_id
  end
end
