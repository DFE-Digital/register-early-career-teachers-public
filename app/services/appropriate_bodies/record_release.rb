module AppropriateBodies
  class RecordRelease < CloseInduction
    def release!
      raise CloseInduction::TeacherHasNoOngoingInductionPeriod if induction_period.blank?

      InductionPeriod.transaction do
        close_induction_period
        delete_submission
        record_close_induction_event!
      end
    end

    private

    def record_close_induction_event!
      Events::Record.record_induction_period_closed_event!(
        author:,
        teacher:,
        appropriate_body:,
        induction_period:
      )
    end
  end
end
