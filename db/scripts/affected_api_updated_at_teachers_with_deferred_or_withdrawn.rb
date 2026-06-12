# Identifies teachers whose participant_status changes from :active to :left/:leaving
# due to the fix that ensures withdrawal/deferral takes precedence.
#
# Run after deploying the teacher_status fix. Touching api_updated_at notifies
# lead providers that the participant_status field has changed.

def find_affected(periods)
  left_ids    = []
  leaving_ids = []

  periods.find_each(batch_size: 1000) do |training_period|
    teacher = training_period.teacher
    status = API::TrainingPeriods::TeacherStatus.new(latest_training_period: training_period, teacher:).status

    if status == :left
      $stdout.print "."
      left_ids << training_period.teacher_id
    end
    if status == :leaving
      $stdout.print "."
      leaving_ids << training_period.teacher_id
    end
  end

  [left_ids, leaving_ids]
end

# Only consider the latest training period per teacher per lead provider,
# as that's what TeacherStatus is evaluated against in the API.
latest_ect_ids    = Metadata::TeacherLeadProvider.where.not(latest_ect_training_period_id: nil).select(:latest_ect_training_period_id)
latest_mentor_ids = Metadata::TeacherLeadProvider.where.not(latest_mentor_training_period_id: nil).select(:latest_mentor_training_period_id)

# Mirrors teacher_is_ect_and_completed_induction? — only ECTs who completed induction
# on or before the training period ended were previously returning :active and are affected.
completed_ect_induction = <<~SQL
  (
    teachers.trs_induction_completed_date IS NOT NULL
    AND (training_periods.finished_on IS NULL OR teachers.trs_induction_completed_date <= training_periods.finished_on)
  ) OR EXISTS (
    SELECT 1 FROM induction_periods
    WHERE induction_periods.teacher_id = teachers.id
      AND induction_periods.finished_on IS NOT NULL
      AND induction_periods.outcome IS NOT NULL
      AND (training_periods.finished_on IS NULL OR induction_periods.finished_on <= training_periods.finished_on)
  )
SQL

# Mirrors teacher_is_mentor_and_completed_training?
completed_mentor_training = <<~SQL
  teachers.mentor_became_ineligible_for_funding_on IS NOT NULL
  AND (training_periods.finished_on IS NULL OR teachers.mentor_became_ineligible_for_funding_on <= training_periods.finished_on)
SQL

withdrawn_ect_periods    = TrainingPeriod.where(id: latest_ect_ids).where.not(withdrawn_at: nil).joins(ect_at_school_period: :teacher).where(completed_ect_induction).includes(ect_at_school_period: :teacher)
deferred_ect_periods     = TrainingPeriod.where(id: latest_ect_ids).where.not(deferred_at: nil).joins(ect_at_school_period: :teacher).where(completed_ect_induction).includes(ect_at_school_period: :teacher)
withdrawn_mentor_periods = TrainingPeriod.where(id: latest_mentor_ids).where.not(withdrawn_at: nil).joins(mentor_at_school_period: :teacher).where(completed_mentor_training).includes(mentor_at_school_period: :teacher)
deferred_mentor_periods  = TrainingPeriod.where(id: latest_mentor_ids).where.not(deferred_at: nil).joins(mentor_at_school_period: :teacher).where(completed_mentor_training).includes(mentor_at_school_period: :teacher)

$stdout.puts "Teachers affected by participant status changes:"
$stdout.puts "Withdrawn ECT:    from a total of #{withdrawn_ect_periods.count} training_periods"
$stdout.puts "Deferred ECT:     from a total of #{deferred_ect_periods.count} training_periods"
$stdout.puts "Withdrawn mentor: from a total of #{withdrawn_mentor_periods.count} training_periods"
$stdout.puts "Deferred mentor:  from a total of #{deferred_mentor_periods.count} training_periods"

withdrawn_ect_left,    withdrawn_ect_leaving    = find_affected(withdrawn_ect_periods)
deferred_ect_left,     deferred_ect_leaving     = find_affected(deferred_ect_periods)
withdrawn_mentor_left, withdrawn_mentor_leaving = find_affected(withdrawn_mentor_periods)
deferred_mentor_left,  deferred_mentor_leaving  = find_affected(deferred_mentor_periods)

$stdout.puts "- ECT withdrawn    — left: #{withdrawn_ect_left.count}, leaving: #{withdrawn_ect_leaving.count}"
$stdout.puts "- ECT deferred     — left: #{deferred_ect_left.count}, leaving: #{deferred_ect_leaving.count}"
$stdout.puts "- Mentor withdrawn — left: #{withdrawn_mentor_left.count}, leaving: #{withdrawn_mentor_leaving.count}"
$stdout.puts "- Mentor deferred  — left: #{deferred_mentor_left.count}, leaving: #{deferred_mentor_leaving.count}"

teacher_ids = (withdrawn_ect_left + withdrawn_ect_leaving + deferred_ect_left + deferred_ect_leaving +
               withdrawn_mentor_left + withdrawn_mentor_leaving + deferred_mentor_left + deferred_mentor_leaving).uniq

Teacher.where(id: teacher_ids).update_all(api_updated_at: Time.current, updated_at: Time.current)
$stdout.puts ""
$stdout.puts "Done — a total of #{teacher_ids.count} teachers have been effected"
