class AddTrainingProgrammeToTrainingPeriods < ActiveRecord::Migration[8.0]
  def change
    # rubocop:disable Rails/NotNullColumn
    add_column :training_periods, :training_programme, :enum, enum_type: 'training_programme', null: false
    # rubocop:enable Rails/NotNullColumn
  end
end
