class ChangeNotStartedStatusOnDeclarations < ActiveRecord::Migration[8.0]
  def up
    execute <<~SQL
      ALTER TYPE declaration_payment_statuses
      RENAME VALUE 'not_started' TO 'no_payment';
    SQL

    execute <<~SQL
      ALTER TYPE declaration_clawback_statuses
      RENAME VALUE 'not_started' TO 'no_clawback';
    SQL

    change_table :declarations, bulk: true do |t|
      t.change_default :payment_status, from: "not_started", to: "no_payment"
      t.change_default :clawback_status, from: "not_started", to: "no_clawback"
    end
  end

  def down
    execute <<~SQL
      ALTER TYPE declaration_payment_statuses
      RENAME VALUE 'no_payment' TO 'not_started';
    SQL

    execute <<~SQL
      ALTER TYPE declaration_clawback_statuses
      RENAME VALUE 'no_clawback' TO 'not_started';
    SQL

    change_table :declarations, bulk: true do |t|
      t.change_default :payment_status, from: "no_payment", to: "not_started"
      t.change_default :clawback_status, from: "no_clawback", to: "not_started"
    end
  end
end
