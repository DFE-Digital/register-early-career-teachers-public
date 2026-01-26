class CreateCallOffContracts < ActiveRecord::Migration[8.0]
  def change
    create_table :call_off_contracts do |t|
      t.references :contractable, polymorphic: true, null: false
      t.integer :recruitment_target, null: false
      t.timestamps
    end
  end
end
