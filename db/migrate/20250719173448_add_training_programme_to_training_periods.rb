class AddTrainingProgrammeToTrainingPeriods < ActiveRecord::Migration[8.0]
  def change
    add_column :training_periods, :training_programme, :enum, enum_type: "training_programme", null: false
  end
end
