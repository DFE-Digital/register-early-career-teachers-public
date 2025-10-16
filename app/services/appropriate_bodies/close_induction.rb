module AppropriateBodies
  # Closing an ongoing induction period comes in three flavours:
  #
  # 1. RecordPass#pass!
  # 2. RecordFail#fail!
  # 3. RecordRelease#release!
  class CloseInduction
    class TeacherHasNoOngoingInductionPeriod < StandardError
    end

    attr_reader :appropriate_body,
      :pending_induction_submission,
      :author,
      :teacher,
      :induction_period

    def initialize(appropriate_body:, pending_induction_submission:, author:)
      @appropriate_body = appropriate_body
      @pending_induction_submission = pending_induction_submission
      @author = author
      @teacher = Teacher.find_by!(trn: pending_induction_submission.trn)
      @induction_period = @teacher.ongoing_induction_period
    end

    private

    def close_induction_period(outcome: nil)
      induction_period.update!(
        number_of_terms: pending_induction_submission.number_of_terms,
        finished_on: pending_induction_submission.finished_on,
        outcome:
      )
    end

    def delete_submission
      pending_induction_submission.update!(delete_at: 24.hours.from_now)
    end
  end
end
