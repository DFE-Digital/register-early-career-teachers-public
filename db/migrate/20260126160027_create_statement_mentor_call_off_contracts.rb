class CreateStatementMentorCallOffContracts < ActiveRecord::Migration[8.0]
  def change
    create_table :statement_mentor_call_off_contracts do |t|
      t.references :statement, foreign_key: { to_table: :statements }

      t.integer :recruitment_target
      t.decimal :payment_per_participant

      t.timestamps
    end
  end
end
