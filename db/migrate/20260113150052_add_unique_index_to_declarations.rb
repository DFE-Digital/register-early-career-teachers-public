class AddUniqueIndexToDeclarations < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_index :declarations,
              %i[training_period_id declaration_type payment_status],
              where: "(payment_status IN ('no_payment','eligible','payable','paid') AND clawback_status = 'no_clawback')",
              unique: true,
              algorithm: :concurrently
  end
end
