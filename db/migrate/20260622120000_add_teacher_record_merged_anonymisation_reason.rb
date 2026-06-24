class AddTeacherRecordMergedAnonymisationReason < ActiveRecord::Migration[8.1]
  def up
    add_enum_value :anonymisation_reasons, "teacher_record_merged"
  end

  def down
    # enum values can't be removed in PostgreSQL
    raise ActiveRecord::IrreversibleMigration
  end
end
