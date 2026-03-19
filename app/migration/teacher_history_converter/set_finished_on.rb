module TeacherHistoryConverter::SetFinishedOn
  # for ECTs, either set to the earliest of deferral date, withdrawal date or
  # induction completion date OR [if this date < ECF1 IR start date] create a
  # one-day stub period
  def ect_finished_on(start_date:, end_date:, deferral_date:, withdrawal_date:, induction_completion_date:)
    work_out_finished_on(start_date:, end_date:, deferral_date:, withdrawal_date:, completion_date: induction_completion_date)
  end

  # for mentors, either set to the earliest of deferral date, withdrawal date
  # or mentor completion date OR [if this date < ECF1 IR start date] create
  # a one-day stub period
  def mentor_finished_on(start_date:, end_date:, deferral_date:, withdrawal_date:, mentor_completion_date:)
    work_out_finished_on(start_date:, end_date:, deferral_date:, withdrawal_date:, completion_date: mentor_completion_date)
  end

private

  def work_out_finished_on(start_date:, end_date:, deferral_date:, withdrawal_date:, completion_date:)
    finished_on = [end_date, deferral_date, withdrawal_date, completion_date].compact.min

    case
    when finished_on.nil?
      nil
    when finished_on <= start_date
      start_date + 1.day
    else
      finished_on
    end
  end
end
