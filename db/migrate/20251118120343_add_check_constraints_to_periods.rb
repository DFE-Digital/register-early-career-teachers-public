class AddCheckConstraintsToPeriods < ActiveRecord::Migration[8.0]
  def change
    add_check_constraint :contract_periods, "finished_on > started_on", name: "period_length_greater_than_zero"
    add_check_constraint :ect_at_school_periods, "finished_on > started_on", name: "period_length_greater_than_zero"
    add_check_constraint :induction_periods, "finished_on > started_on", name: "period_length_greater_than_zero"
    add_check_constraint :mentor_at_school_periods, "finished_on > started_on", name: "period_length_greater_than_zero"
    add_check_constraint :mentorship_periods, "finished_on > started_on", name: "period_length_greater_than_zero"
    add_check_constraint :training_periods, "finished_on > started_on", name: "period_length_greater_than_zero"
  end
end
