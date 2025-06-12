# Run BeginECTInductionJob for teachers who have:
# - trs_induction_status = 'RequiredToComplete'
# - induction periods that have started (started_on is not null)
# - induction periods that are ongoing (finished_on is null)

teachers = Teacher.left_joins(:induction_periods)
                  .where(trs_induction_status: 'RequiredToComplete')
                  .where.not(induction_periods: { started_on: nil })
                  .where(induction_periods: { finished_on: nil })
                  .includes(:induction_periods)

Rails.logger.debug "Found #{teachers.count} teachers matching criteria"

teachers.each do |teacher|
  ongoing_induction_period = teacher.induction_periods.find { |period| period.finished_on.nil? && period.started_on.present? }

  if ongoing_induction_period
    Rails.logger.debug "Processing teacher TRN: #{teacher.trn}, Start date: #{ongoing_induction_period.started_on}"

    BeginECTInductionJob.perform_later(
      trn: teacher.trn,
      start_date: ongoing_induction_period.started_on
    )

    Rails.logger.debug "  - Enqueued BeginECTInductionJob"
  else
    Rails.logger.debug "Skipping teacher TRN: #{teacher.trn} - no valid ongoing induction period found"
  end
end

Rails.logger.debug "Script completed"
