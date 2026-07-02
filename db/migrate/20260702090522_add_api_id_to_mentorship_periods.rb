class AddAPIIdToMentorshipPeriods < ActiveRecord::Migration[8.1]
  def change
    add_column :mentorship_periods, :api_id, :uuid, null: false, default: "gen_random_uuid()"
    add_index :mentorship_periods, :api_id, unique: true
  end
end
