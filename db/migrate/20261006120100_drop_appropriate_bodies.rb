class DropAppropriateBodies < ActiveRecord::Migration[8.1]
  def change
    drop_table "appropriate_bodies" do |t|
      t.datetime "created_at", null: false
      t.bigint "dfe_sign_in_organisation_id", null: false
      t.string "name", null: false
      t.datetime "updated_at", null: false
      t.index %w[dfe_sign_in_organisation_id], name: "index_appropriate_bodies_on_dfe_sign_in_organisation_id"
      t.foreign_key "dfe_sign_in_organisations"
    end
  end
end
