class AddMoreIndexesToImproveTeachersQuery < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    # Withdrawn scopes
    add_index :training_periods,
              :id,
              name: "idx_training_periods_withdrawn",
              where: "withdrawn_at IS NOT NULL",
              algorithm: :concurrently

    # Deferred scopes
    add_index :training_periods,
              :id,
              name: "idx_training_periods_deferred",
              where: "deferred_at IS NOT NULL",
              algorithm: :concurrently

    # Active scopes (neither withdrawn nor deferred)
    add_index :training_periods,
              :id,
              name: "idx_training_periods_active",
              where: "withdrawn_at IS NULL AND deferred_at IS NULL",
              algorithm: :concurrently
  end
end
