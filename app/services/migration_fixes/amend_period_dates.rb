class AmendPeriodDates
  def amend_start!(period:, started_on:)
    period.started_on = started_on
    period.save!

    if period.class.in? [ECTAtSchoolPeriod, MentorAtSchoolPeriod]
      amend_start!(period: period.training_periods.order(:started_on).first, started_on:)
      amend_start!(period: period.mentorship_periods.order(:started_on).first, started_on:)
    end
  end

  def amend_finish!(period:, finished_on:)
    period.finished_on = finished_on
    period.save!

    if period.class.in? [ECTAtSchoolPeriod, MentorAtSchoolPeriod]
      amend_finish!(period: period.training_periods.order(:started_on).last, finshed_on:)
      amend_finish!(period: period.mentorship_periods.order(:started_on).last, finshed_on:)
    end
  end
end
