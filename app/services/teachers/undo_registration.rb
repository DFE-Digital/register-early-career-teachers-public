module Teachers
  class UndoRegistration
    class NoPeriodsToCloseError < StandardError; end
    class UndoOutcomeChangedError < StandardError; end

    attr_reader :author, :at_school_period, :reason, :teacher

    delegate :training_periods, :mentorship_periods, to: :at_school_period

    def initialize(author:, at_school_period:, reason:)
      @author = author
      @at_school_period = at_school_period
      @reason = reason
      @teacher = at_school_period.teacher
    end

    def undo!(expected_action: nil)
      ActiveRecord::Base.transaction do
        at_school_period.lock!

        action = periods_will_be_closed? ? "close" : "delete"

        raise UndoOutcomeChangedError if expected_action.present? && expected_action != action

        if action == "close"
          raise NoPeriodsToCloseError, "No open periods to close" unless periods_to_close?

          finish_periods!
        else
          delete_periods!
          anonymiser.anonymise! if anonymiser.permitted?
        end

        record_undo_registration_event!
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
