module AppropriateBodies
  class RecordOutcome
    attr_reader :teacher, :pending_induction_submission, :appropriate_body, :author

    def initialize(appropriate_body:, pending_induction_submission:, teacher:, author:)
      @appropriate_body = appropriate_body
      @pending_induction_submission = pending_induction_submission
      @teacher = teacher
      @author = author
    end

    def pass!
      record_outcome!(:pass)
    end

    def fail!
      record_outcome!(:fail)
    end

  private

    def record_outcome!(outcome)
      raise Errors::ECTHasNoOngoingInductionPeriods if ongoing_induction_period.blank?

      ActiveRecord::Base.transaction do
        close_induction_period(outcome)
        case outcome
        when :pass
          send_pass_induction_notification_to_trs
          record_pass_induction_event!
        when :fail
          send_fail_induction_notification_to_trs
          record_fail_induction_event!
        end
      end
    end

    def ongoing_induction_period
      @ongoing_induction_period ||= ::Teachers::InductionPeriod.new(teacher).ongoing_induction_period
    end

    def record_pass_induction_event!
      Events::Record.record_teacher_passes_induction_event!(
        author:,
        teacher:,
        appropriate_body:,
        induction_period: ongoing_induction_period,
        pending_induction_submission_batch: pending_induction_submission.pending_induction_submission_batch
      )
    end

    def record_fail_induction_event!
      Events::Record.record_teacher_fails_induction_event!(
        author:,
        teacher:,
        appropriate_body:,
        induction_period: ongoing_induction_period,
        pending_induction_submission_batch: pending_induction_submission.pending_induction_submission_batch
      )
    end

    def close_induction_period(outcome)
      ongoing_induction_period.update!(
        finished_on: pending_induction_submission.finished_on,
        outcome:,
        number_of_terms: pending_induction_submission.number_of_terms
      )
    end

    def send_fail_induction_notification_to_trs
      FailECTInductionJob.perform_later(
        trn: pending_induction_submission.trn,
        start_date: induction_start_date,
        completed_date: pending_induction_submission.finished_on,
        pending_induction_submission_id: pending_induction_submission.id
      )
    end

    def send_pass_induction_notification_to_trs
      PassECTInductionJob.perform_later(
        trn: pending_induction_submission.trn,
        start_date: induction_start_date,
        completed_date: pending_induction_submission.finished_on,
        pending_induction_submission_id: pending_induction_submission.id
      )
    end

    def induction_start_date
      @induction_start_date ||= ::Teachers::Induction.new(teacher).induction_start_date
    end
  end
end
