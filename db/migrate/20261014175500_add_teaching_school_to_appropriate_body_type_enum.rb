class AddTeachingSchoolToAppropriateBodyTypeEnum < ActiveRecord::Migration[8.1]
  def up
    add_enum_value :appropriate_body_type, "teaching_school", before: "teaching_school_hub", if_not_exists: true
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
