module AppropriateBodies
  class ClaimECTActionsComponent < ApplicationComponent
    attr_reader :pending_induction_submission

    def initialize(teacher:, pending_induction_submission:, current_appropriate_body:)
      @teacher = teacher
      @pending_induction_submission = pending_induction_submission
      @current_appropriate_body = current_appropriate_body
    end

    delegate :exempt?, :passed?, :failed?, to: :pending_induction_submission

    def registration_blocked?
      passed? || failed? || exempt? || claimed_by_another_ab?
    end

    def show_claim_form?
      !registration_blocked? && !induction_status.completed?
    end

    def blocked_registration_message
      if passed?
        "You cannot register #{name}. Our records show that #{name} has already passed their induction."
      elsif failed?
        "You cannot register #{name}. Our records show that #{name} has already failed their induction."
      elsif exempt?
        "You cannot register #{name}. Our records show that #{name} is exempt from completing their induction."
      elsif claimed_by_another_ab?
        "You cannot register #{name}. Our records show that #{name} is completing their induction with another appropriate body."
      end
    end

  private

    attr_reader :teacher, :current_appropriate_body

    include InductionHelper

    def induction_status
      ::Teachers::InductionStatus.new(
        teacher:,
        induction_periods: teacher&.induction_periods,
        trs_induction_status: pending_induction_submission.trs_induction_status
      )
    end

    def name
      PendingInductionSubmissions::Name.new(pending_induction_submission).full_name
    end

    def claimed_by_another_ab?
      teacher&.ongoing_induction_period && !claiming_body?(teacher, current_appropriate_body)
    end
  end
end
