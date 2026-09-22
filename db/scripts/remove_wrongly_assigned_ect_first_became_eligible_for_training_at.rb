# the `Teacher.ect_first_became_eligible_for_training_at` cannot be changed once set so son-of-patch cannot
# update the value without modificiations so handling separately here as a special case.
#

author = Events::SystemAuthor.new

Teacher
  .where(trs_induction_status: "RequiredToComplete")
  .where.not(ect_first_became_eligible_for_training_at: nil)
  .find_each do |teacher|
    ActiveRecord::Base.transaction do
      teacher.ect_first_became_eligible_for_training_at = nil
      modifications = teacher.changes
      teacher.save!(validate: false)

      Events::Record.record_teacher_ect_first_became_eligible_for_training_reset_event!(author:, teacher:, modifications:)
    end
  end
