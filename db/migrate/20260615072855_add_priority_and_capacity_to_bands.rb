class AddPriorityAndCapacityToBands < ActiveRecord::Migration[8.1]
  def change
    change_table :contract_banded_fee_structure_bands, bulk: true do |t|
      t.integer :priority
      t.integer :capacity
    end

    add_index :contract_banded_fee_structure_bands, %i[banded_fee_structure_id priority], unique: true
  end
end
