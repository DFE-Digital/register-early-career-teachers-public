class AddTrainingRecordIdToECTAtSchoolPeriods < ActiveRecord::Migration[8.0]
  def change
    add_column :ect_at_school_periods, :training_record_id, :uuid, null: false, default: "gen_random_uuid()"
  end
end
