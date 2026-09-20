class AddAssociationsToAppropriateBodyPeriods < ActiveRecord::Migration[8.1]
  def up
    add_reference :appropriate_body_periods, :teaching_school_hub, foreign_key: true
    add_reference :appropriate_body_periods, :school, foreign_key: true
    add_reference :appropriate_body_periods, :national_body, foreign_key: true
    add_reference :appropriate_body_periods, :local_authority, foreign_key: true
  end

  def down
    remove_reference :appropriate_body_periods, :teaching_school_hub, index: true, foreign_key: true
    remove_reference :appropriate_body_periods, :school, index: true, foreign_key: true
    remove_reference :appropriate_body_periods, :national_body, index: true, foreign_key: true
    remove_reference :appropriate_body_periods, :local_authority, index: true, foreign_key: true
  end
end
