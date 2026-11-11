class AddECTEngagementThresholdClaimedToTeachers < ActiveRecord::Migration[8.1]
  def change
    add_column :teachers, :ect_engagement_threshold_claimed, :boolean, default: false, null: false
  end
end
