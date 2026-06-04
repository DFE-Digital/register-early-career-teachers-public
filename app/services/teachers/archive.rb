module Teachers
  class Archive
    attr_reader :author, :period, :reason, :teacher

    delegate :training_periods, :mentorship_periods, to: :period

    def initialize(author:, period:, reason:)
      @author = author
      @period = period
      @reason = reason
      @teacher = period.teacher
    end

    def archive
      ActiveRecord::Base.transaction do
        if billable_declarations?
          finish_periods!
        else
          delete_periods!
          anonymise_teacher! unless induction_period_exists?
        end

        record_archived_event!
      end

      API::Teachers::Query.new.teacher_by_id(teacher.id)
    end

  private

    def billable_declarations?
      declarations.billable.exists? || declarations.refundable.exists?
    end

    def declarations
      Declaration.where(training_period: training_periods)
    end

    def finish_periods!
      mentorship_periods.find_each { |mp| mp.update!(finished_on: Time.zone.today) }
      training_periods.find_each { |tp| tp.update!(finished_on: Time.zone.today) }
      period.update!(finished_on: Time.zone.today)
    end

    def delete_periods!
      mentorship_periods.destroy_all
      training_periods.destroy_all
      period.destroy!
    end

    def anonymise_teacher!
      teacher.update!(
        trs_first_name: nil,
        trs_last_name: nil,
        corrected_name: nil,
        trn: nil,
        trnless: true,
        archived_reason: reason,
        archived_at: Time.zone.now
      )
    end

    def induction_period_exists?
      teacher.induction_periods.exists?
    end

    def record_archived_event!
      Events::Record.record_teacher_archived_event!(
        author:,
        teacher:,
        reason:
      )
    end
  end
end
