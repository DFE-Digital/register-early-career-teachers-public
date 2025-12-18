module Teachers
  class RecordOutcomeComponent < ApplicationComponent
    class InvalidOutcomeError < StandardError; end
    class MissingAppropriateBodyError < StandardError; end
    class InvalidServiceError < StandardError; end

    attr_reader :service, :teacher_full_name

    include UserModes

    delegate :appropriate_body,
             :teacher,
             :pending_induction_submission,
             :outcome,
             to: :service

    # @param mode [Symbol] either :admin or :appropriate_body
    # @param service [Object]
    # @raise [Teachers::RecordOutcomeComponent::InvalidOutcomeError]
    # @raise [Teachers::RecordOutcomeComponent::MissingAppropriateBodyError]
    def initialize(mode:, service:)
      super

      @service = service

      raise(InvalidServiceError) if unsupported_service?
      raise(InvalidOutcomeError) if unsupported_outcome?
      raise(MissingAppropriateBodyError) if appropriate_body_required?

      @teacher_full_name = ::Teachers::Name.new(teacher).full_name
    end

  private

    def submit_text
      type = { pass: "pass", fail: "failing" }[outcome]
      "Record #{type} outcome for #{teacher_full_name}"
    end

    def url
      path_prefix = { admin: "admin", appropriate_body: "ab" }[mode]
      type = { pass: "passed", fail: "failed" }[outcome]
      public_send("#{path_prefix}_teacher_record_#{type}_outcome_path", teacher)
    end

    def appropriate_body_required?
      appropriate_body_mode? && service.appropriate_body.nil?
    end

    def unsupported_outcome?
      !outcome.in?(::INDUCTION_OUTCOMES.keys)
    end

    def unsupported_service?
      !service.is_a?(::AppropriateBodies::RecordPass) &&
        !service.is_a?(::AppropriateBodies::RecordFail)
    end

    def failed?
      service.is_a?(::AppropriateBodies::RecordFail)
    end
  end
end
