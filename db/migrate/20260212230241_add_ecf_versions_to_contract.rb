class AddECFVersionsToContract < ActiveRecord::Migration[8.0]
  def change
    change_table :contracts, bulk: true do |t|
      t.string :ecf_contract_version, null: false, default: "1.0.0"
      t.string :ecf_mentor_contract_version
    end
  end
end
