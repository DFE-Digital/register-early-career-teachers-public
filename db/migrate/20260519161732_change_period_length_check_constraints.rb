class ChangePeriodLengthCheckConstraints < ActiveRecord::Migration[8.1]
  def up
    # ECTAtSchoolPeriods
    remove_check_constraint :ect_at_school_periods, name: "period_length_greater_than_zero", if_exists: true
    add_check_constraint :ect_at_school_periods, "finished_on >= started_on", name: "finished_on_not_before_started_on", if_not_exists: true, validate: true

    # MentorAtSchoolPeriods
    remove_check_constraint :mentor_at_school_periods, name: "period_length_greater_than_zero", if_exists: true
    add_check_constraint :mentor_at_school_periods, "finished_on >= started_on", name: "finished_on_not_before_started_on", if_not_exists: true, validate: true

    # TrainingPeriods
    remove_check_constraint :training_periods, name: "period_length_greater_than_zero", if_exists: true
    add_check_constraint :training_periods, "finished_on >= started_on", name: "finished_on_not_before_started_on", if_not_exists: true, validate: true

    # MentorshipPeriods
    remove_check_constraint :mentorship_periods, name: "period_length_greater_than_zero", if_exists: true
    add_check_constraint :mentorship_periods, "finished_on >= started_on", name: "finished_on_not_before_started_on", if_not_exists: true, validate: true

    # ContractPeriods
    remove_check_constraint :contract_periods, name: "period_length_greater_than_zero", if_exists: true
    add_check_constraint :contract_periods, "finished_on >= started_on", name: "finished_on_not_before_started_on", if_not_exists: true, validate: true
  end

  def down
    # ECTAtSchoolPeriods
    remove_check_constraint :ect_at_school_periods, name: "finished_on_not_before_started_on", if_exists: true
    add_check_constraint :ect_at_school_periods, "finished_on > started_on", name: "period_length_greater_than_zero", if_not_exists: true, validate: true

    # MentorAtSchoolPeriods
    remove_check_constraint :mentor_at_school_periods, name: "finished_on_not_before_started_on", if_exists: true
    add_check_constraint :mentor_at_school_periods, "finished_on > started_on", name: "period_length_greater_than_zero", if_not_exists: true, validate: true

    # TrainingPeriods
    remove_check_constraint :training_periods, name: "finished_on_not_before_started_on", if_exists: true
    add_check_constraint :training_periods, "finished_on > started_on", name: "period_length_greater_than_zero", if_not_exists: true, validate: true

    # MentorshipPeriods
    remove_check_constraint :mentorship_periods, name: "finished_on_not_before_started_on", if_exists: true
    add_check_constraint :mentorship_periods, "finished_on > started_on", name: "period_length_greater_than_zero", if_not_exists: true, validate: true

    # ContractPeriods
    remove_check_constraint :contract_periods, name: "finished_on_not_before_started_on", if_exists: true
    add_check_constraint :contract_periods, "finished_on > started_on", name: "period_length_greater_than_zero", if_not_exists: true, validate: true
  end
end
