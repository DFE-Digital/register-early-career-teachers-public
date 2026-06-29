class ChangeInductionPeriodLengthCheckConstraint < ActiveRecord::Migration[8.1]
  def up
    remove_check_constraint :induction_periods, name: "period_length_greater_than_zero", if_exists: true
    add_check_constraint :induction_periods, "finished_on >= started_on", name: "finished_on_not_before_started_on", if_not_exists: true, validate: true
  end

  def down
    remove_check_constraint :induction_periods, name: "finished_on_not_before_started_on", if_exists: true
    add_check_constraint :induction_periods, "finished_on > started_on", name: "period_length_greater_than_zero", if_not_exists: true, validate: true
  end
end
