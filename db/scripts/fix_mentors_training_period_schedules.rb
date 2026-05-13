# This script finds training periods for mentors that are on a reduced schedule and updates them to the corresponding standard schedule.
# This is necessary because mentors should not be on reduced schedules, which are only applicable for ECTs.

SCHEDULE_MAPPINGS = {
  "ecf-reduced-april": "ecf-standard-april",
  "ecf-reduced-january": "ecf-standard-january",
  "ecf-reduced-september": "ecf-standard-september"
}.freeze

TrainingPeriod.where.not(mentor_at_school_period_id: nil).where(schedule_id: Schedule.where(identifier: SCHEDULE_MAPPINGS.keys).select(:id)).find_each do |training_period|
  # Double check: Only update training periods for mentors, not ECTs
  next unless training_period.for_mentor?

  new_schedule = Schedule.find_by!(
    identifier: SCHEDULE_MAPPINGS[training_period.schedule.identifier.to_sym],
    contract_period_year: training_period.schedule.contract_period_year
  )

  Rails.logger.debug "Updating TrainingPeriod ID: #{training_period.id} from Schedule: #{training_period.schedule.identifier} to Schedule: #{new_schedule.identifier}"

  training_period.update!(schedule_id: new_schedule.id)
end
