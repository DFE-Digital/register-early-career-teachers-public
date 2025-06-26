class AddAPIIdToSchoolPartnerships < ActiveRecord::Migration[8.0]
  def change
    add_column :school_partnerships, :api_id, :uuid, default: -> { "gen_random_uuid()" }, null: false
    add_index :school_partnerships, :api_id, unique: true
  end
end
