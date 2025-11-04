module InductionStatusHelper
  def induction_status_from(teacher:, pending_induction_submission:)
    Teachers::InductionStatus.new(
      teacher:,
      trs_induction_status: pending_induction_submission.trs_induction_status
    )
  end
end
