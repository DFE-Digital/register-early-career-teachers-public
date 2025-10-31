module AppropriateBodies
  class RecordRelease < CloseInduction
    def call
      super

      InductionPeriod.transaction do
        close_induction_period
        delete_submission
        record_close_induction_event!
      end
    end

    alias_method :release!, :call

  private

    def record_close_induction_event!
      Events::Record.record_induction_period_closed_event!(
        author:,
        teacher:,
        appropriate_body:,
        induction_period: ongoing_induction_period
      )
    end
  end
end
