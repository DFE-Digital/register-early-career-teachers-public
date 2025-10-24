module Teachers
  class RecordOutcomeComponent < ApplicationComponent
    class InvalidOutcomeError < StandardError; end
    class MissingAppropriateBodyError < StandardError; end

    include UserModes

    attr_reader :teacher,
                :teacher_full_name,
                :model,
                :outcome,
                :appropriate_body

    # @param mode [Symbol] either :admin or :appropriate_body
    # @param teacher [Teacher]
    # @param pending_induction_submission [PendingInductionSubmission]
    # @param outcome [Symbol] either :pass or :fail
    # @param appropriate_body [AppropriateBody, nil]
    # @raise [Teachers::RecordOutcomeComponent::InvalidOutcomeError]
    # @raise [Teachers::RecordOutcomeComponent::MissingAppropriateBodyError]
    def initialize(mode:, teacher:, pending_induction_submission:, outcome:, appropriate_body: nil)
      super

      raise(InvalidOutcomeError) unless outcome.in?(::INDUCTION_OUTCOMES.keys)
      raise(MissingAppropriateBodyError) if appropriate_body_mode? && appropriate_body.nil?

      @teacher = teacher
      @teacher_full_name = ::Teachers::Name.new(teacher).full_name
      @model = pending_induction_submission
      @outcome = outcome
      @appropriate_body = appropriate_body
    end

  private

    def submit_text
      type = { pass: "pass", fail: "failing" }[outcome]
      "Record #{type} outcome for #{teacher_full_name}"
    end

    def appeal_notice
      "#{teacher_full_name} can appeal this outcome. You must tell them about their right to appeal and the appeal process."
    end

    def url
      path_prefix = { admin: "admin", appropriate_body: "ab" }[mode]
      type = { pass: "passed", fail: "failed" }[outcome]
      public_send("#{path_prefix}_teacher_record_#{type}_outcome_path", teacher)
    end

    def failed?
      outcome == :fail
    end
  end
end
