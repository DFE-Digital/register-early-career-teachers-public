module API::Teachers
  class Defer
    include API::Teachers::SharedAction

    DEFERRAL_REASONS = TrainingPeriod.deferral_reasons.values.map(&:dasherize).freeze

    attribute :reason

    validates :reason,
              inclusion: {
                in: DEFERRAL_REASONS,
                message: "The property '#/reason' must be a valid reason"
              },
              allow_blank: false
    validate :not_already_deferred
    validate :not_already_withdrawn

    def defer
      return false if invalid?

      ActiveRecord::Base.transaction do
        training_period.deferred_at = Time.zone.now
        training_period.deferral_reason = reason.underscore
        training_period.finished_on = [training_period.finished_on, training_period.deferred_at.to_date].compact.min
        training_period.save!

        record_deferred_event!
      end

      true
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

    def record_deferred_event!
      return unless training_period.saved_changes?

      Events::Record.record_teacher_defers_training_period_event!(
        author: Events::LeadProviderAPIAuthor.new(lead_provider:),
        training_period:,
        teacher:,
        lead_provider:,
        modifications: training_period.saved_changes
      )
    end
  end
end
