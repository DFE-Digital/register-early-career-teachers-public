module Admin
  # Renders a message if an ECT cannot be imported
  class ImportECTEligibilityComponent < ApplicationComponent
    attr_reader :pending_induction_submission, :name

    def initialize(pending_induction_submission:)
      @pending_induction_submission = pending_induction_submission
      @name = ::PendingInductionSubmissions::Name.new(pending_induction_submission).full_name
    end

    delegate :exempt?,
      :passed?,
      :failed?,
      :no_qts?,
      :prohibited_from_teaching?,
      to: :pending_induction_submission

    # @return [Boolean]
    def render?
      blocked_message.present?
    end

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
      end
    end
  end
end
