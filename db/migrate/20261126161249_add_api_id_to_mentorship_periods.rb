class AddAPIIdToMentorshipPeriods < ActiveRecord::Migration[8.0]
  def change
    add_column :mentorship_periods, :api_id, :uuid, default: -> { "gen_random_uuid()" }, null: false
    add_index :mentorship_periods, :api_id, unique: true
  end
end
