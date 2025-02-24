class RenameAppropriateBodyLegacyIdToDqtId < ActiveRecord::Migration[8.0]
  def change
    rename_column :appropriate_bodies, :legacy_id, :dqt_id
  end
end
