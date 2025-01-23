module InductionStatusHelper
  def induction_status_from(teacher:, pending_induction_submission:)
    Teachers::InductionStatus.new(
      teacher:,
      induction_periods: teacher&.induction_periods,
      trs_induction_status: pending_induction_submission.trs_induction_status
    )
  end
end
