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
      ActiveRecord::Base.transaction do
        success = [
          close_induction_period(:pass),
          send_pass_induction_notification_to_trs,
          record_pass_induction_event!
        ].all?

        success or raise ActiveRecord::Rollback
      end
    end

    def fail!
      ActiveRecord::Base.transaction do
        success = [
          close_induction_period(:fail),
          send_fail_induction_notification_to_trs,
          record_fail_induction_event!
        ].all?

        success or raise ActiveRecord::Rollback
      end
    end

  private

    def active_induction_period
      @active_induction_period ||= ::Teachers::InductionPeriod.new(teacher).active_induction_period
    end

    def record_pass_induction_event!
      Events::Record.record_appropriate_body_passes_teacher_event(
        author:,
        teacher:,
        appropriate_body:,
        induction_period: active_induction_period
      )
    end

    def record_fail_induction_event!
      Events::Record.record_appropriate_body_fails_teacher_event(
        author:,
        teacher:,
        appropriate_body:,
        induction_period: active_induction_period
      )
    end

    def close_induction_period(outcome)
      active_induction_period.update(
        finished_on: pending_induction_submission.finished_on,
        outcome:,
        number_of_terms: pending_induction_submission.number_of_terms
      )
    end

    def send_fail_induction_notification_to_trs
      FailECTInductionJob.perform_later(
        trn: pending_induction_submission.trn,
        completion_date: pending_induction_submission.finished_on.to_s,
        pending_induction_submission_id: pending_induction_submission.id,
        teacher_id: teacher.id
      )
    end

    def send_pass_induction_notification_to_trs
      PassECTInductionJob.perform_later(
        trn: pending_induction_submission.trn,
        completion_date: pending_induction_submission.finished_on.to_s,
        pending_induction_submission_id: pending_induction_submission.id,
        teacher_id: teacher.id
      )
    end
  end
end
