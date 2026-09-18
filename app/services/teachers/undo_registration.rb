module Teachers
  class UndoRegistration
    class NoPeriodsToCloseError < StandardError; end
    class UndoOutcomeChangedError < StandardError; end
    class AffectedPeriodsChangedError < StandardError; end
    class RegistrationAlreadyUndoneError < StandardError; end

    attr_reader :author, :at_school_period, :reason, :teacher

    delegate :training_periods, :mentorship_periods, to: :at_school_period

    def initialize(author:, at_school_period:, reason:)
      @author = author
      @at_school_period = at_school_period
      @reason = reason
      @teacher = at_school_period.teacher
    end

    def undo!(
      expected_action: nil,
      expected_training_period_ids: nil,
      expected_mentorship_period_ids: nil
    )
      ActiveRecord::Base.transaction do
        lock_at_school_period!

        action = periods_will_be_closed? ? "close" : "delete"

        raise UndoOutcomeChangedError if expected_action.present? && expected_action != action
        raise AffectedPeriodsChangedError unless affected_periods_match?(
          action:,
          expected_training_period_ids:,
          expected_mentorship_period_ids:
        )

        if action == "close"
          raise NoPeriodsToCloseError, "No open periods to close" unless periods_to_close?

          finish_periods!
        else
          delete_periods!
          anonymiser.anonymise! if anonymiser.permitted?
        end

        record_undo_registration_event!
        action
      end
    end

    def periods_will_be_closed? = billable_or_refundable_declarations_exist?

    def undoable? = !periods_will_be_closed? || periods_to_close?

    def finish_date_for(period)
      [period.started_on, Date.current].max
    end

  private

    def anonymiser
      @anonymiser ||= Teachers::Anonymise.new(teacher:, reason:)
    end

    def lock_at_school_period!
      # Reload the school period so we can catch if another undo has deleted it.
      @at_school_period = at_school_period.class.lock.find(at_school_period.id)
    rescue ActiveRecord::RecordNotFound
      raise RegistrationAlreadyUndoneError
    end

    def billable_or_refundable_declarations_exist?
      Declaration.where(training_period: training_periods)
        .merge(Declaration.billable.or(Declaration.refundable))
        .exists?
    end

    def periods_to_close?
      at_school_period.unfinished? ||
        training_periods.unfinished.exists? ||
        mentorship_periods.unfinished.exists?
    end

    def affected_periods_match?(action:, expected_training_period_ids:, expected_mentorship_period_ids:)
      return true if expected_training_period_ids.nil? && expected_mentorship_period_ids.nil?
      return false if expected_training_period_ids.nil? || expected_mentorship_period_ids.nil?

      affected_period_ids(training_periods, action:) == expected_training_period_ids.sort &&
        affected_period_ids(mentorship_periods, action:) == expected_mentorship_period_ids.sort
    end

    def affected_period_ids(periods, action:)
      periods = periods.where(finished_on: nil) if action == "close"

      periods.ids.sort
    end

    def finish_periods!
      mentorship_periods.where(finished_on: nil).find_each { |period| period.finish!(finish_date_for(period)) }
      training_periods.where(finished_on: nil).find_each { |period| period.finish!(finish_date_for(period)) }
      at_school_period.finish!(finish_date_for(at_school_period)) if at_school_period.finished_on.nil?
    end

    def delete_periods!
      mentorship_periods.find_each(&:destroy!)
      training_periods.find_each(&:destroy!)
      at_school_period.destroy!
    end

    def record_undo_registration_event!
      Events::Record.record_undo_registration_event!(
        author:,
        teacher:,
        reason:
      )
    end
  end
end
