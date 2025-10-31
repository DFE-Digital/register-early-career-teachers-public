module AppropriateBodies
  class RecordPass < CloseInduction
    def outcome = :pass

    def call(*)
      super

      validate_submission(context: :record_outcome)

      InductionPeriod.transaction do
        close_induction_period
        delete_submission
        sync_with_trs
        update_event_history
      end
    end

  private

    def update_event_history
      Events::Record.record_teacher_passes_induction_event!(
        author:,
        teacher:,
        appropriate_body:,
        induction_period: ongoing_induction_period
      )
    end

    def sync_with_trs
      PassECTInductionJob.perform_later(
        trn:,
        start_date: first_induction_period.started_on,
        completed_date: last_induction_period.finished_on
      )
    end
  end
end
