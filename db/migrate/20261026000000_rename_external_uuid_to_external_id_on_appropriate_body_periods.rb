class RenameExternalUuidToExternalIdOnAppropriateBodyPeriods < ActiveRecord::Migration[8.1]
  def change
    rename_column :appropriate_body_periods, :external_uuid, :external_id
  end
end
