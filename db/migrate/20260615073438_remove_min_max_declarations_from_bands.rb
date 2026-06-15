class RemoveMinMaxDeclarationsFromBands < ActiveRecord::Migration[8.1]
  def change
    change_table :contract_banded_fee_structure_bands, bulk: true do |t|
      t.remove :min_declarations, type: :integer
      t.remove :max_declarations, type: :integer
    end
  end
end
