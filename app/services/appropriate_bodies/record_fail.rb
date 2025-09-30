module AppropriateBodies
  class RecordFail < CloseInduction
    def fail!
      raise CloseInduction::TeacherHasNoOngoingInductionPeriod if induction_period.blank?

      InductionPeriod.transaction do
        close_induction_period(outcome: 'fail')
        delete_submission
        send_fail_induction_notification_to_trs
        record_fail_induction_event!
      end
    end

  private

    def record_fail_induction_event!
      Events::Record.record_teacher_fails_induction_event!(
        author:,
        teacher:,
        appropriate_body:,
        induction_period:
      )
    end

    def send_fail_induction_notification_to_trs
      FailECTInductionJob.perform_later(
        trn: pending_induction_submission.trn,
        start_date: teacher.first_induction_period.started_on,
        completed_date: pending_induction_submission.finished_on,
        pending_induction_submission_id: pending_induction_submission.id
      )
    end
  end
end
