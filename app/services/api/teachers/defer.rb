module API::Teachers
  class Defer
    include API::Concerns::Teachers::SharedAction

    DEFERRAL_REASONS = TrainingPeriod.deferral_reasons.values.map(&:dasherize).freeze

    attribute :reason

    validates :reason, presence: { message: "Enter a '#/reason'." }
    validates :reason,
              inclusion: {
                in: DEFERRAL_REASONS,
                message: "The entered '#/reason' is not recognised for the given participant. Check details and try again."
              }, allow_blank: true
    validate :not_already_deferred
    validate :not_already_withdrawn
    validate :not_started_yet

    def defer
      return false if invalid?

      Teachers::Defer.new(
        author: Events::LeadProviderAPIAuthor.new(lead_provider:),
        lead_provider:,
        reason:,
        teacher:,
        training_period:
      ).defer
    end

  private

    def not_already_withdrawn
      return if errors[:teacher_api_id].any?
      return unless training_status&.withdrawn?

      errors.add(:teacher_api_id, "The '#/teacher_api_id' is already withdrawn.")
    end

    def not_already_deferred
      return if errors[:teacher_api_id].any?
      return unless training_status&.deferred?

      errors.add(:teacher_api_id, "The '#/teacher_api_id' is already deferred.")
    end

    def not_started_yet
      return if errors[:teacher_api_id].any?
      return unless training_period&.started_on&.future?

      errors.add(:teacher_api_id, "The '#/teacher_api_id' has not yet started their training so cannot be deferred")
    end
  end
end
