module API::Teachers
  class Withdraw
    include API::Teachers::SharedAction

    WITHDRAWAL_REASONS = TrainingPeriod.withdrawal_reasons.values.map(&:dasherize).freeze

    attribute :reason

    validates :reason, presence: { message: "Enter a '#/reason'." }
    validates :reason, inclusion: {
      in: WITHDRAWAL_REASONS,
      message: "The entered '#/reason' is not recognised for the given participant. Check details and try again."
    }, allow_blank: true
    validate :not_already_withdrawn

    def withdraw
      return false unless valid?

      ActiveRecord::Base.transaction do
        training_period.withdrawn_at = Time.zone.now
        training_period.withdrawal_reason = reason.underscore
        training_period.finished_on = [training_period.finished_on, training_period.withdrawn_at.to_date].compact.min
        training_period.save!

        record_withdraw_event!
      end
    end

  private

    def not_already_withdrawn
      return if errors[:teacher_api_id].any?
      return unless training_status&.withdrawn?

      errors.add(:teacher_api_id, "The '#/teacher_api_id' is already withdrawn.")
    end

    def record_withdraw_event!
      return unless training_period.saved_changes?

      Events::Record.record_teacher_withdraws_training_period_event!(
        author: Events::LeadProviderAPIAuthor.new(lead_provider:),
        training_period:,
        teacher:,
        lead_provider:,
        modifications: training_period.saved_changes
      )
    end
  end
end
