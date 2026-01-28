class RemoveIneligiblePaymentStateFromDeclarations < ActiveRecord::Migration[8.0]
  def up
    # Declarations are not yet in production, we can safely
    # remove ineligible from non-production environments.
    Declaration.where(payment_status: :ineligible).destroy_all

    # Drop ineligibility_reason column as its now redundant.
    remove_column :declarations, :ineligibility_reason
    drop_enum :ineligibility_reasons

    # Create a payment status enum without ineligible.
    create_enum :declaration_payment_statuses_without_ineligible, %w[no_payment eligible payable paid voided]

    # Migrate existing data to the new enum type.
    change_table :declarations, bulk: true do |t|
      t.change_default :payment_status, from: :no_payment, to: nil
      t.change :payment_status, :declaration_payment_statuses_without_ineligible, using: "payment_status::text::declaration_payment_statuses_without_ineligible"
      t.change_default :payment_status, from: nil, to: :no_payment
    end

    # Drop the enum with ineligible type.
    drop_enum :declaration_payment_statuses

    # Rename the new enum type (without ineligible) to the original name.
    rename_enum :declaration_payment_statuses_without_ineligible, to: :declaration_payment_statuses
  end

  def down
    # Recreate the original enum with ineligible.
    create_enum :declaration_payment_statuses_with_ineligible, %w[no_payment eligible payable paid voided ineligible]

    # Migrate existing data to the new enum type.
    change_table :declarations, bulk: true do |t|
      t.change_default :payment_status, from: :no_payment, to: nil
      t.change :payment_status, :declaration_payment_statuses_with_ineligible, using: "payment_status::text::declaration_payment_statuses_with_ineligible"
      t.change_default :payment_status, from: nil, to: :no_payment
    end

    # Drop the enum without ineligible type.
    drop_enum :declaration_payment_statuses

    # Rename the new enum type (with ineligible) to the original name.
    rename_enum :declaration_payment_statuses_with_ineligible, to: :declaration_payment_statuses

    # Recreate ineligibility reasons enum and column.
    create_enum :ineligibility_reasons, %w[duplicate]
    add_column :declarations, :ineligibility_reason, :ineligibility_reasons
  end
end
