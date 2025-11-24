module Teachers
  class Defer
    attr_reader :author, :lead_provider, :reason, :teacher, :training_period

    def initialize(author:, lead_provider:, reason:, teacher:, training_period:)
      @author = author
      @lead_provider = lead_provider
      @reason = reason
      @teacher = teacher
      @training_period = training_period
    end

    def defer
      rollback_redundant_training_period!

      ActiveRecord::Base.transaction do
        training_period.deferred_at = Time.zone.now
        training_period.deferral_reason = reason.underscore
        training_period.finished_on = [training_period.finished_on, training_period.deferred_at.to_date].compact.min
        training_period.save!

        record_deferred_event!
      end

      teacher
    end

  private

    def rollback_redundant_training_period!
      return unless training_period.started_on.today? && previous_training_period_for_lead_provider

      training_period.destroy!
      @training_period = previous_training_period_for_lead_provider
    end

    def previous_training_period_for_lead_provider
      @previous_training_period_for_lead_provider ||= training_period
        .predecessors
        .latest_first
        .find { it.lead_provider == lead_provider }
    end

    def record_deferred_event!
      return unless training_period.saved_changes?

      Events::Record.record_teacher_training_period_deferred_event!(
        author:,
        training_period:,
        teacher:,
        lead_provider:,
        modifications: training_period.saved_changes
      )
    end
  end
end
