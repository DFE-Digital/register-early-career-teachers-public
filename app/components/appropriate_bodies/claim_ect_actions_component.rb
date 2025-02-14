# frozen_string_literal: true

module AppropriateBodies
  class ClaimECTActionsComponent < ViewComponent::Base
    def initialize(teacher:, pending_induction_submission:, current_appropriate_body:)
      @teacher = teacher
      @pending_induction_submission = pending_induction_submission
      @current_appropriate_body = current_appropriate_body
    end

    private

    attr_reader :teacher, :pending_induction_submission, :current_appropriate_body

    def claiming_body?(teacher, appropriate_body)
      return false unless teacher

      current_period = ::Teachers::Induction.new(teacher).current_induction_period
      return false unless current_period

      current_period.appropriate_body_id == appropriate_body.id
    end

    def induction_status_from(teacher:, pending_induction_submission:)
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
