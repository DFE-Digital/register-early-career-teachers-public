class RemoveIneligiblePaymentStateFromDeclarations < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def up
    # Declarations are not yet in production, we can safely
    # remove ineligible from non-production environments
    Declaration.where(payment_status: :ineligible).destroy_all

    # Drop ineligibility_reason column as its now redundant
    remove_column :declarations, :ineligibility_reason
    drop_enum :ineligibility_reasons

    # Create a new enum and column without ineligible
    create_enum :declaration_payment_statuses_without_ineligible, %w[no_payment eligible payable paid voided]
    add_column :declarations, :payment_status_without_ineligible, :declaration_payment_statuses_without_ineligible, null: false, default: :no_payment

    # Copy data to new column
    Declaration.update_all("payment_status_without_ineligible = payment_status::text::declaration_payment_statuses_without_ineligible")

    # Remove the old column and enum
    remove_column :declarations, :payment_status
    drop_enum :declaration_payment_statuses

    # Rename the new column and enum to the original names
    rename_column :declarations, :payment_status_without_ineligible, :payment_status
    rename_enum :declaration_payment_statuses_without_ineligible, to: :declaration_payment_statuses

    # Add unique index back in (it gets dropped when we drop the column)
    add_index :declarations,
              %i[training_period_id declaration_type payment_status],
              where: "(payment_status IN ('no_payment','eligible','payable','paid') AND clawback_status = 'no_clawback')",
              unique: true,
              name: "idx_unique_declarations",
              algorithm: :concurrently
  end

  def down
    # Recreate ineligibility reasons enum and column.
    create_enum :ineligibility_reasons, %w[duplicate]
    add_column :declarations, :ineligibility_reason, :ineligibility_reasons

    # Create a new enum and column with ineligible
    create_enum :declaration_payment_statuses_with_ineligible, %w[no_payment eligible payable paid voided ineligible]
    add_column :declarations, :payment_status_with_ineligible, :declaration_payment_statuses_with_ineligible, null: false, default: :no_payment

    # Copy data to new column
    Declaration.update_all("payment_status_with_ineligible = payment_status::text::declaration_payment_statuses_with_ineligible")

    # Remove the old column and enum
    remove_column :declarations, :payment_status
    drop_enum :declaration_payment_statuses

    # Rename the new column and enum to the original names
    rename_column :declarations, :payment_status_with_ineligible, :payment_status
    rename_enum :declaration_payment_statuses_with_ineligible, to: :declaration_payment_statuses

    # Add unique index back in (it gets dropped when we drop the column)
    add_index :declarations,
              %i[training_period_id declaration_type payment_status],
              where: "(payment_status IN ('no_payment','eligible','payable','paid') AND clawback_status = 'no_clawback')",
              unique: true,
              name: "idx_unique_declarations",
              algorithm: :concurrently
  end
end
