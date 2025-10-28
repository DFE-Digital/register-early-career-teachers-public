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
