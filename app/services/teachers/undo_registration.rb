module Teachers
  class UndoRegistration
    attr_reader :author, :at_school_period, :reason, :teacher

    delegate :training_periods, :mentorship_periods, to: :at_school_period

    def initialize(author:, at_school_period:, reason:)
      @author = author
      @at_school_period = at_school_period
      @reason = reason
      @teacher = at_school_period.teacher
    end

    def undo!
      ActiveRecord::Base.transaction do
        if billable_or_refundable_declarations_exist?
          finish_periods!
        else
          delete_periods!
          anonymiser.anonymise! if anonymiser.permitted?
        end

        record_undo_registration_event!
      end

      API::Teachers::Query.new.teacher_by_id(teacher.id)
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

    def finish_periods!
      mentorship_periods.where(finished_on: nil).find_each { |period| period.finish!(finish_date_for(period)) }
      training_periods.where(finished_on: nil).find_each { |period| period.finish!(finish_date_for(period)) }
      at_school_period.finish!(finish_date_for(at_school_period)) if at_school_period.finished_on.nil?
    end

    def finish_date_for(period)
      [period.started_on, Date.current].max
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
