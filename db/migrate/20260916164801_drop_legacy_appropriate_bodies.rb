class DropLegacyAppropriateBodies < ActiveRecord::Migration[8.1]
  def up
    drop_table :legacy_appropriate_bodies
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
