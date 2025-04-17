# This script fixes appropriate body events where the happened_at timestamp
# is set to the time the event happened (i.e., the time the AB reported
# the fact to us) rather than the time the thing happened to the teacher.
#
# We already hold the time the event was recorded in `created_at` so we don't
# lose anything by switching these.
#
# It will result in us being able to choose whether we show the timeline in the
# order of the thing being recorded vs the actual date the thing
# happened. Additionally, it might provide some insight into delays between the
# two.

since_go_live_date = (Date.new(2025, 2, 19)..)
closure_events = %w[
  induction_period_closed
  teacher_fails_induction
]

Event.transaction do
  Event
    .where(created_at: since_go_live_date, event_type: 'appropriate_body_claims_teacher')
    .find_each { |e| e.update!(happened_at: e.induction_period.started_on) }

  Event
    .where(created_at: since_go_live_date, event_type: closure_events)
    .find_each { |e| e.update!(happened_at: e.induction_period.finished_on) }
end
