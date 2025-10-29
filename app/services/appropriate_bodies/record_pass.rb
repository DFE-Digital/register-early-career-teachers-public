module AppropriateBodies
  class RecordPass < CloseInduction
    def call
      super

      InductionPeriod.transaction do
        close_induction_period(outcome: 'pass')
        delete_submission
        send_pass_induction_notification_to_trs
        record_pass_induction_event!
      end
    end

    alias_method :pass!, :call

  private

    def record_pass_induction_event!
      Events::Record.record_teacher_passes_induction_event!(
        author:,
        teacher:,
        appropriate_body:,
        induction_period: ongoing_induction_period
      )
    end

    def send_pass_induction_notification_to_trs
      PassECTInductionJob.perform_later(
        trn:,
        start_date: first_induction_period.started_on,
        completed_date: last_induction_period.finished_on
      )
    end
  end
end
