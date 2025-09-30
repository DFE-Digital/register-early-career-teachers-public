module AppropriateBodies
  class RecordPass < CloseInduction
    def pass!
      raise CloseInduction::TeacherHasNoOngoingInductionPeriod if induction_period.blank?

      InductionPeriod.transaction do
        close_induction_period(outcome: 'pass')
        delete_submission
        send_pass_induction_notification_to_trs
        record_pass_induction_event!
      end
    end

  private

    def record_pass_induction_event!
      Events::Record.record_teacher_passes_induction_event!(
        author:,
        teacher:,
        appropriate_body:,
        induction_period:
      )
    end

    def send_pass_induction_notification_to_trs
      PassECTInductionJob.perform_later(
        trn: pending_induction_submission.trn,
        start_date: teacher.first_induction_period.started_on,
        completed_date: pending_induction_submission.finished_on,
        pending_induction_submission_id: pending_induction_submission.id
      )
    end
  end
end
