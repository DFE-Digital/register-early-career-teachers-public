class RemoveECFContractVersions < ActiveRecord::Migration[8.1]
  def change
    change_table :contracts, bulk: true do |t|
      t.remove :ecf_contract_version, type: :string
      t.remove :ecf_mentor_contract_version, type: :string
    end
  end
end
