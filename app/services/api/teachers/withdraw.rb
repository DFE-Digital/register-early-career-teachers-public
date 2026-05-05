module API::Teachers
  class Withdraw
    include API::Concerns::Teachers::SharedAction

    WITHDRAWAL_REASONS = TrainingPeriod.withdrawal_reasons.values.map(&:dasherize).freeze
    MENTOR_ONLY_WITHDRAWAL_REASONS = %w[mentor-no-longer-being-mentor].freeze

    attribute :reason

    validates :reason, presence: { message: "Enter a '#/reason'." }
    validates :reason, inclusion: {
      in: WITHDRAWAL_REASONS,
      message: "The entered '#/reason' is not recognised for the given participant. Check details and try again."
    }, allow_blank: true
    validate :not_already_withdrawn
    validate :training_period_has_started
    validate :training_for_at_least_one_day
    validate :reason_valid_for_teacher_type

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

      errors.add(:teacher_api_id, "You cannot withdraw #/teacher_api_id. This is because they have not been training with you for at least one day.")
    end

    def training_for_at_least_one_day
      return if errors[:teacher_api_id].any?
      return unless training_period&.started_on&.today?

      errors.add(:teacher_api_id, "You cannot defer or withdraw this participant today. You need to try again tomorrow as the training was recently changed for this participant.")
    end

    def reason_valid_for_teacher_type
      return if errors.any?
      return unless training_period&.for_ect?
      return unless MENTOR_ONLY_WITHDRAWAL_REASONS.include?(reason)

      errors.add(:reason, "You cannot withdraw an ECT for this reason. The ECT is not a mentor.")
    end
  end
end
