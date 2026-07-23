class CreateStatementAuditNotes < ActiveRecord::Migration[8.0]
  def change
    create_table :statement_audit_notes do |t|
      t.references :statement, null: false, foreign_key: true
      t.text :body, null: false

      t.timestamps
    end
  end
end
