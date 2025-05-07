class AddECFIdToModels < ActiveRecord::Migration[8.0]
  def change
    add_column :schools, :ecf_id, :uuid, null: false, default: -> { "gen_random_uuid()" }
    add_column :lead_providers, :ecf_id, :uuid, null: false, default: -> { "gen_random_uuid()" }
    add_column :delivery_partners, :ecf_id, :uuid, null: false, default: -> { "gen_random_uuid()" }
  end
end
