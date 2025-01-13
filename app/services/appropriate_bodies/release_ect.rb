module AppropriateBodies
  class ReleaseECT
    attr_reader :teacher, :pending_induction_submission, :author, :appropriate_body

    def initialize(appropriate_body:, pending_induction_submission:, author:)
      @appropriate_body = appropriate_body
      @pending_induction_submission = pending_induction_submission
      @teacher = Teacher.find_by!(trn: pending_induction_submission.trn)
      @author = author
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
      Events::Record.new(
        author: author,
        event_type: :ect_released,
        heading: "#{teacher_name} was released by #{appropriate_body.name}",
        teacher:,
        appropriate_body:,
        happened_at: Time.zone.now
      ).record_event!
    end

    def teacher_name
      ::Teachers::Name.new(teacher).full_name
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
