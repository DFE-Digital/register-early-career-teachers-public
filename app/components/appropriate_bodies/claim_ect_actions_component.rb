# frozen_string_literal: true

module AppropriateBodies
  class ClaimECTActionsComponent < ViewComponent::Base
    def initialize(teacher:, pending_induction_submission:, current_appropriate_body:)
      @teacher = teacher
      @pending_induction_submission = pending_induction_submission
      @current_appropriate_body = current_appropriate_body
      @induction = teacher ? ::Teachers::Induction.new(teacher) : nil
    end

    def registration_blocked?
      pending_induction_submission.exempt? || (teacher && induction&.current_induction_period && !claiming_body?(teacher, current_appropriate_body))
    end

    def show_claim_form?
      !registration_blocked? && !induction_status.completed?
    end

    def blocked_registration_message
      if pending_induction_submission.exempt?
        "You cannot register #{name}. Our records show that #{name} is exempt from completing their induction."
      else
        "You cannot register #{name}. Our records show that #{name} is completing their induction with another appropriate body."
      end
    end

    def name
      pending_induction_submission_full_name(pending_induction_submission)
    end

  private

    attr_reader :teacher, :pending_induction_submission, :current_appropriate_body, :induction

    include InductionHelper

    def induction_status
      ::Teachers::InductionStatus.new(
        teacher:,
        induction_periods: teacher&.induction_periods,
        trs_induction_status: pending_induction_submission.trs_induction_status
      )
    end

    def pending_induction_submission_full_name(pending_induction_submission)
      PendingInductionSubmissions::Name.new(pending_induction_submission).full_name
    end
  end
end
