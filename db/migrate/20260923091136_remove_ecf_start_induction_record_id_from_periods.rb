class RemoveECFStartInductionRecordIdFromPeriods < ActiveRecord::Migration[8.0]
  def change
    remove_column :mentor_at_school_periods, :ecf_start_induction_record_id, :uuid
    remove_column :ect_at_school_periods, :ecf_start_induction_record_id, :uuid
    remove_column :training_periods, :ecf_start_induction_record_id, :uuid
    remove_column :mentorship_periods, :ecf_start_induction_record_id, :uuid
  end
end
