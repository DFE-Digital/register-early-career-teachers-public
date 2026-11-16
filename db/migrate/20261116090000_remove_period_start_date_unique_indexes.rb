class RemovePeriodStartDateUniqueIndexes < ActiveRecord::Migration[7.2]
  def up
    remove_index :ect_at_school_periods, name: "index_ect_at_school_periods_on_school_id_teacher_id_started_on"
    remove_index :ect_at_school_periods, name: "index_ect_at_school_periods_on_teacher_id_started_on"
    remove_index :mentor_at_school_periods, name: "idx_on_school_id_teacher_id_started_on_17d46e7783"
    remove_index :mentorship_periods, name: "index_mentorship_periods_on_ect_at_school_period_id_started_on"
    remove_index :mentorship_periods, name: "idx_on_mentor_at_school_period_id_ect_at_school_per_d69dffeecc"
  end

  def down
    add_index :ect_at_school_periods, %i[school_id teacher_id started_on], unique: true, name: "index_ect_at_school_periods_on_school_id_teacher_id_started_on"
    add_index :ect_at_school_periods, %i[teacher_id started_on], unique: true, name: "index_ect_at_school_periods_on_teacher_id_started_on"
    add_index :mentor_at_school_periods, %i[school_id teacher_id started_on], unique: true, name: "idx_on_school_id_teacher_id_started_on_17d46e7783"
    add_index :mentorship_periods, %i[ect_at_school_period_id started_on], unique: true, name: "index_mentorship_periods_on_ect_at_school_period_id_started_on"
    add_index :mentorship_periods, %i[mentor_at_school_period_id ect_at_school_period_id started_on], unique: true, name: "idx_on_mentor_at_school_period_id_ect_at_school_per_d69dffeecc"
  end
end
