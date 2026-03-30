class AddIndexToStatementsPaymentDate < ActiveRecord::Migration[8.0]
  def change
    add_index :statements, :payment_date
  end
end
