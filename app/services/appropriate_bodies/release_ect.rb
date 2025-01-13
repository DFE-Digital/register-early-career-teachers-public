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
      InductionPeriod.transaction do
        ongoing_induction_period.update!(
          finished_on: pending_induction_submission.finished_on,
          number_of_terms: pending_induction_submission.number_of_terms
        )

        pending_induction_submission.destroy!
        record_event!
      end
    end

  private

    def record_event!
      Events::Record.record_appropriate_body_releases_teacher_event!(
        author:,
        teacher:,
        appropriate_body:,
        induction_period:
      )
    end

    def ongoing_induction_period
      ongoing_induction_periods = InductionPeriod.ongoing.for_teacher(teacher)

      if ongoing_induction_periods.count.zero?
        fail(Errors::ECTHasNoOngoingInductionPeriods)
      end

      ongoing_induction_periods.first
    end
  end
end
