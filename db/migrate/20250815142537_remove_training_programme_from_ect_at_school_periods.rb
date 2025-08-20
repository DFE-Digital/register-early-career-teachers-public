class RemoveTrainingProgrammeFromECTAtSchoolPeriods < ActiveRecord::Migration[8.0]
  def up
    remove_column :ect_at_school_periods, :training_programme
  end

  def down
    add_column :ect_at_school_periods, :training_programme, :enum, enum_type: 'training_programme'
  end
end
