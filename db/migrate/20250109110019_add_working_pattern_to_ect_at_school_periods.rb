class AddWorkingPatternToECTAtSchoolPeriods < ActiveRecord::Migration[8.0]
  def up
    execute <<-SQL
      CREATE TYPE working_pattern AS ENUM ('part_time', 'full_time');
    SQL

    add_column :ect_at_school_periods, :working_pattern, :working_pattern
  end

  def down
    remove_column :ect_at_school_periods, :working_pattern

    execute <<-SQL
      DROP TYPE working_pattern;
    SQL
  end
end
