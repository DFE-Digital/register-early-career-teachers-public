module API::Teachers
  class Defer < Action
    DEFERRAL_REASONS = TrainingPeriod.deferral_reasons.values.map(&:dasherize).freeze

    attribute :reason

    validates :reason,
              inclusion: {
                in: DEFERRAL_REASONS,
                message: "The property '#/reason' must be a valid reason"
              },
              allow_blank: false
    validate :not_already_deferred
    validate :not_withdrawn

    def defer
      return false if invalid?

      ActiveRecord::Base.transaction do
        deferral_date = Time.zone.now

        updates = {}
        updates[:deferral_reason] = reason.underscore
        updates[:deferred_at] = deferral_date
        updates[:finished_on] = deferral_date.to_date unless training_period.finished_on && training_period.finished_on < deferral_date

        training_period.update!(updates)

        record_teacher_training_period_deferred_event!

        teacher.reload
      end

      true
    end

  private

    def not_withdrawn
      return if errors.any?

      errors.add(:participant_id, "The participant is already withdrawn") if training_period && training_status == :withdrawn
    end

    def not_already_deferred
      return if errors.any?

      errors.add(:participant_id, "The participant is already deferred") if training_period && training_status == :deferred
    end

    def record_teacher_training_period_deferred_event!
      return unless training_period.saved_changes?

      Events::Record.record_teacher_training_period_deferred_event!(
        author:,
        teacher:,
        training_period:,
        modifications: training_period.saved_changes
      )
    end
  end
end
