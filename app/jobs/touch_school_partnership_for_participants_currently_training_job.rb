# Ensure changes to `participants_currently_training` in the
# API::SchoolPartnershipSerializer are reflected in the `updated_at`.
#
# Job is scheduled to run daily at 12:01am.
class TouchSchoolPartnershipForParticipantsCurrentlyTrainingJob < ApplicationJob
  def perform
    training_periods_starting_today = TrainingPeriod.where(started_on: Time.zone.today)
    training_periods_finished_yesterday = TrainingPeriod.where(finished_on: Time.zone.yesterday)

    SchoolPartnership
      .where(id: training_periods_starting_today.or(training_periods_finished_yesterday).select(:school_partnership_id))
      .update_all(api_updated_at: Time.current)
  end
end
