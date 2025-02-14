# frozen_string_literal: true

module AppropriateBodies
  class ClaimECTActionsComponent < ViewComponent::Base
    def initialize(teacher:, pending_induction_submission:, current_appropriate_body:)
      @teacher = teacher
      @pending_induction_submission = pending_induction_submission
      @current_appropriate_body = current_appropriate_body
      @induction = teacher ? ::Teachers::Induction.new(teacher) : nil
    end

    def show_inset_text?
      teacher && induction&.current_induction_period && !claiming_body?(teacher, current_appropriate_body)
    end

    def show_claim_form?
      !show_inset_text? && !induction_status.completed?
    end

    private

    attr_reader :teacher, :pending_induction_submission, :current_appropriate_body, :induction

    def claiming_body?(teacher, appropriate_body)
      induction&.with_appropriate_body?(appropriate_body)
    end

    def induction_status
      ::Teachers::InductionStatus.new(
        teacher:,
        induction_periods: teacher&.induction_periods,
        trs_induction_status: pending_induction_submission.trs_induction_status
      )
    end

    def pending_induction_submission_full_name(pending_induction_submission)
      "#{pending_induction_submission.trs_first_name} #{pending_induction_submission.trs_last_name}"
    end
  end
end
