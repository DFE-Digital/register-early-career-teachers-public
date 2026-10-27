class AddExternalUuidToAppropriateBodyPeriod < ActiveRecord::Migration[8.1]
  def change
    add_column :appropriate_body_periods, :external_uuid, :uuid, default: -> { "gen_random_uuid()" }, null: false
    add_index :appropriate_body_periods, :external_uuid, unique: true
  end
end
