module API::Teachers
  class Withdraw
    include API::Concerns::Teachers::SharedAction

    WITHDRAWAL_REASONS = TrainingPeriod.withdrawal_reasons.values.map(&:dasherize).freeze

    attribute :reason

    validates :reason, presence: { message: "Enter a '#/reason'." }
    validates :reason, inclusion: {
      in: WITHDRAWAL_REASONS,
      message: "The entered '#/reason' is not recognised for the given participant. Check details and try again."
    }, allow_blank: true
    validate :not_already_withdrawn
    validate :training_period_has_started

    def withdraw
      return false unless valid?

      Teachers::Withdraw.new(
        author: Events::LeadProviderAPIAuthor.new(lead_provider:),
        lead_provider:,
        reason:,
        teacher:,
        training_period:
      ).withdraw
    end

  private

    def not_already_withdrawn
      return if errors[:teacher_api_id].any?
      return unless training_status&.withdrawn?

      errors.add(:teacher_api_id, "The '#/teacher_api_id' is already withdrawn.")
    end

    def training_period_has_started
      return if errors[:teacher_api_id].any?
      return unless training_period&.started_on&.future?

      errors.add(:teacher_api_id, "You cannot withdraw '#/teacher_api_id'. This is because they've not started their training.")
    end
  end
end
