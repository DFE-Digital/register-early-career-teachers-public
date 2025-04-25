module Admin
  class ReopenInductionPeriod
    class ReopenInductionError < StandardError; end

    attr_reader :author, :induction_period

    def initialize(author:, induction_period:)
      @author = author
      @induction_period = induction_period
    end

    def reopen_induction_period!
      check_can_reopen_period!

      existing_outcome = induction_period.outcome
      induction_period.finished_on = nil
      induction_period.number_of_terms = nil
      induction_period.outcome = nil
      modifications = induction_period.changes

      ActiveRecord::Base.transaction do
        induction_period.save!
        record_reopen_event!(modifications)
        notify_trs_of_outcome_change! if existing_outcome.present?
      end
    end

  private

    delegate :teacher, :appropriate_body, to: :induction_period

    def check_can_reopen_period!
      check_induction_period_is_complete!
      check_induction_period_is_the_latest!
    end

    def check_induction_period_is_complete!
      raise ReopenPeriodError, "Cannot reopen an ongoing induction" unless induction_period.complete?
    end

    def check_induction_period_is_the_latest!
      last_period = ::Teachers::InductionPeriod.new(teacher).last_induction_period

      raise ReopenPeriodError, "Only the latest period can be reopened" unless induction_period == last_period
    end

    def record_reopen_event!(modifications)
      Events::Record.record_induction_period_reopened_event!(
        author:,
        induction_period:,
        modifications:,
        teacher:,
        appropriate_body:
      )
    end

    def notify_trs_of_outcome_change!
      ReopenInductionJob.perform_later(trn: teacher.trn, start_date: induction_start_date)
    end

    def induction_start_date
      @induction_start_date ||= ::Teachers::Induction.new(teacher).induction_start_date
    end
  end
end
