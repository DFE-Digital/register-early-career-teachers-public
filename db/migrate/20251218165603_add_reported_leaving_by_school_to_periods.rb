class AddReportedLeavingBySchoolToPeriods < ActiveRecord::Migration[8.0]
  def change
    add_column :ect_at_school_periods, :reported_leaving_by_school_id, :bigint
    add_index :ect_at_school_periods, :reported_leaving_by_school_id
    add_foreign_key :ect_at_school_periods, :schools, column: :reported_leaving_by_school_id

    add_column :mentor_at_school_periods, :reported_leaving_by_school_id, :bigint
    add_index :mentor_at_school_periods, :reported_leaving_by_school_id
    add_foreign_key :mentor_at_school_periods, :schools, column: :reported_leaving_by_school_id
  end
end
