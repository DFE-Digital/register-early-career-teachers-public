class AddContractIdToStatements < ActiveRecord::Migration[8.0]
  def change
    add_reference :statements, :contract, foreign_key: true, index: true
  end
end
