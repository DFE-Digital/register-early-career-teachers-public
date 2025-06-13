class AllowNullSchoolPartnershipIdOnTrainingPeriods < ActiveRecord::Migration[8.0]
  def up
    change_column :training_periods, :school_partnership_id, :bigint, null: true
  end

  def down
    change_column :training_periods, :school_partnership_id, :bigint, null: false
  end
end
