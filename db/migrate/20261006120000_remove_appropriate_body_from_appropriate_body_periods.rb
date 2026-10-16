class RemoveAppropriateBodyFromAppropriateBodyPeriods < ActiveRecord::Migration[8.1]
  def change
    remove_column :appropriate_body_periods, :appropriate_body_id, :bigint
  end
end
