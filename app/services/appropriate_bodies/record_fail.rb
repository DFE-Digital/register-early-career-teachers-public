module AppropriateBodies
  class RecordFail < CloseInduction
    def call
      super

      InductionPeriod.transaction do
        close_induction_period(outcome: 'fail')
        delete_submission
        send_fail_induction_notification_to_trs
        record_fail_induction_event!
      end
    end

    alias_method :fail!, :call

  private

    def record_fail_induction_event!
      Events::Record.record_teacher_fails_induction_event!(
        author:,
        teacher:,
        appropriate_body:,
        induction_period: ongoing_induction_period
      )
    end

    def send_fail_induction_notification_to_trs
      FailECTInductionJob.perform_later(
        trn:,
        start_date: first_induction_period.started_on,
        completed_date: last_induction_period.finished_on
      )
    end
  end
end
