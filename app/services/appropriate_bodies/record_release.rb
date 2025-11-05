module AppropriateBodies
  class RecordRelease < CloseInduction
    def call(*)
      super

      validate_submission(context: :release_ect)

      InductionPeriod.transaction do
        close_induction_period
        delete_submission
        update_event_history
      end
    end

  private

    def update_event_history
      Events::Record.record_induction_period_closed_event!(
        author:,
        teacher:,
        appropriate_body_period:,
        induction_period: ongoing_induction_period
      )
    end
  end
end
