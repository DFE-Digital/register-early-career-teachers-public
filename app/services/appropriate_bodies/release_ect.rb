module AppropriateBodies
  class ReleaseECT
    attr_reader :teacher, :pending_induction_submission, :author, :appropriate_body, :induction_period

    def initialize(appropriate_body:, pending_induction_submission:, author:)
      @appropriate_body = appropriate_body
      @pending_induction_submission = pending_induction_submission
      @teacher = Teacher.find_by!(trn: pending_induction_submission.trn)
      @author = author
      @induction_period = ongoing_induction_period
    end

    def release!
      raise Errors::ECTHasNoOngoingInductionPeriods if ongoing_induction_period.blank?

      InductionPeriod.transaction do
        ongoing_induction_period.update!(
          finished_on: pending_induction_submission.finished_on,
          number_of_terms: pending_induction_submission.number_of_terms
        )

        pending_induction_submission.update(delete_at: 24.hours.from_now)
        record_event!
      end
    end

  private

    def record_event!
      Events::Record.record_induction_period_closed_event!(
        author:,
        teacher:,
        appropriate_body:,
        induction_period:,
        pending_induction_submission_batch: pending_induction_submission.pending_induction_submission_batch
      )
    end

    def ongoing_induction_period
      @ongoing_induction_period ||= ::Teachers::InductionPeriod.new(teacher).ongoing_induction_period
    end
  end
end
