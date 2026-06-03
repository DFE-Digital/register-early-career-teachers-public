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

withdrawn_ect_periods    = TrainingPeriod.where(id: latest_ect_ids).where.not(withdrawn_at: nil).includes(ect_at_school_period: :teacher)
deferred_ect_periods     = TrainingPeriod.where(id: latest_ect_ids).where.not(deferred_at: nil).includes(ect_at_school_period: :teacher)
withdrawn_mentor_periods = TrainingPeriod.where(id: latest_mentor_ids).where.not(withdrawn_at: nil).includes(mentor_at_school_period: :teacher)
deferred_mentor_periods  = TrainingPeriod.where(id: latest_mentor_ids).where.not(deferred_at: nil).includes(mentor_at_school_period: :teacher)

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
