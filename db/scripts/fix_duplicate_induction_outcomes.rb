# @see https://github.com/DFE-Digital/register-early-career-teachers-public/pull/2153
#
# Before adding validation to ensure:
# - an induction period only has an outcome if it has finished
# - a teacher only ever has one induction period with an outcome
#
# We need to correct 2 records removing passing outcomes where this is not the case,
# and their corresponding events from the timeline.
#
InductionPeriod.transaction do
  [
    58_001, # teacher's later IP has an outcome. Manual admin West lakes/One Cumbria
    28_791, # teacher's current IP is ongoing
  ].each do |id|
    induction_period = InductionPeriod.find(id)
    induction_period.update!(outcome: nil)
    Event.find_by(event_type: :teacher_passes_induction, induction_period:).delete
  end
end
