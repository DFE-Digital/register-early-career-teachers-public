class AddCallOffContractAssignmentToDeclaration < ActiveRecord::Migration[8.0]
  def change
    add_reference :declarations, :call_off_contract_assignment, foreign_key: true, null: true
  end
end
