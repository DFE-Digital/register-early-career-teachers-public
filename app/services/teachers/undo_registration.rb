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
        if billable_or_refundable_declarations?
          finish_periods!
        else
          delete_periods!
          anonymise_teacher! unless induction_period_exists?
        end

        record_undo_registration_event!
      end

      API::Teachers::Query.new.teacher_by_id(teacher.id)
    end

  private

    def billable_or_refundable_declarations?
      declarations.billable.exists? || declarations.refundable.exists?
    end

    def declarations
      Declaration.where(training_period: training_periods)
    end

    def finish_periods!
      mentorship_periods.find_each(&:finish!)
      training_periods.find_each(&:finish!)
      at_school_period.finish!
    end

    def delete_periods!
      mentorship_periods.destroy_all
      training_periods.destroy_all
      at_school_period.destroy!
    end

    def anonymise_teacher!
      teacher.update!(
        trs_first_name: nil,
        trs_last_name: nil,
        corrected_name: nil,
        trn: nil,
        trnless: true,
        anonymisation_reason: reason,
        anonymised_at: Time.zone.now
      )
    end

    def induction_period_exists?
      teacher.induction_periods.exists?
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
