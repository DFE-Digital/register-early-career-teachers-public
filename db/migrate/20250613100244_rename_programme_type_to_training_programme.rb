class RenameProgrammeTypeToTrainingProgramme < ActiveRecord::Migration[8.0]
  def up
    rename_enum :programme_type, :training_programme
    rename_column :schools, :last_chosen_programme_type, :last_chosen_training_programme
    rename_column :ect_at_school_periods, :programme_type, :training_programme
  end

  def down
    rename_enum :training_programme, :programme_type
    rename_column :ect_at_school_periods, :training_programme, :programme_type
    rename_column :schools, :last_chosen_training_programme, :last_chosen_programme_type
  end
end
