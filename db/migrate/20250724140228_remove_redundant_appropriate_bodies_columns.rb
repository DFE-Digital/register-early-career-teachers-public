class RemoveRedundantAppropriateBodiesColumns < ActiveRecord::Migration[8.0]
  def change
    change_table :appropriate_bodies, bulk: true do |t|
      t.remove :establishment_number, type: :integer, null: true
      t.remove :local_authority_code, type: :integer, null: true
    end
  end
end
