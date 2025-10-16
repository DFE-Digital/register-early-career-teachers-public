module AppropriateBodies
  # Renders a message if an ECT cannot be claimed or a CTA if they can
  class ClaimECTEligibilityComponent < ApplicationComponent
    attr_reader :pending_induction_submission,
      :appropriate_body,
      :teacher,
      :name

    def initialize(pending_induction_submission:, appropriate_body:, teacher:)
      @pending_induction_submission = pending_induction_submission
      @appropriate_body = appropriate_body
      @teacher = teacher
      @name = ::PendingInductionSubmissions::Name.new(pending_induction_submission).full_name
    end

    delegate :exempt?,
      :passed?,
      :failed?,
      :no_qts?,
      :prohibited_from_teaching?,
      to: :pending_induction_submission

    # @return [String, nil]
    def blocked_message
      if no_qts?
        "You cannot register #{name}. Our records show that #{name} does not have their qualified teacher status (QTS)."
      elsif prohibited_from_teaching?
        "You cannot register #{name}. Our records show that #{name} is prohibited from teaching."
      elsif passed?
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

    # @return [Boolean]
    def claimed_by_another_ab?
      return false if teacher&.ongoing_induction_period.blank?

      teacher.ongoing_induction_period.appropriate_body != appropriate_body
    end
  end
end
