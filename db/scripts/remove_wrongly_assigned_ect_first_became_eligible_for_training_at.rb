# the `Teacher.ect_first_became_eligible_for_training_at` cannot be changed once set so son-of-patch cannot
# update the value without modificiations so handling separately here as a special case.
#

Teacher
  .where(trs_induction_status: "RequiredToComplete")
  .where.not(ect_first_became_eligible_for_training_at: nil)
  .find_each do |teacher|
    teacher.update_attribute(:ect_first_became_eligible_for_training_at, nil) # rubocop:disable Rails/SkipsModelValidations
  end
