class RenameAPIIdToECFIdInStatementAdjustments < ActiveRecord::Migration[8.0]
  def change
    change_table :statement_adjustments, bulk: true do |t|
      t.rename :api_id, :ecf_id
      t.change_default :ecf_id, from: -> { "gen_random_uuid()" }, to: nil
      t.change_null :ecf_id, true
      t.index :ecf_id, unique: true
    end
  end
end
