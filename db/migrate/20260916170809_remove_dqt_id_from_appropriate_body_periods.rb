class RemoveDqtIdFromAppropriateBodyPeriods < ActiveRecord::Migration[8.1]
  def change
    # DQT ID was only used by RIAB importers to marry legacy data to current data.
    # It is no longer needed now that the import is complete.
    remove_column :appropriate_body_periods, :dqt_id, :uuid
  end
end
