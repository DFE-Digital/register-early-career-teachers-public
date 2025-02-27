module Admin
  class UpdateInductionPeriodService
    class RecordedOutcomeError < StandardError; end

    attr_reader :induction_period, :params, :author

    def initialize(induction_period:, params:, author:)
      @induction_period = induction_period
      @params = params
      @author = author
    end

    def update_induction!
      validate_can_update!

      previous_start_date = induction_period.started_on
      induction_period.assign_attributes(params)
      modifications = induction_period.changes

      ActiveRecord::Base.transaction do
        induction_period.save!
        record_admin_update_event(modifications)
        notify_trs_of_start_date_change(previous_start_date)
      end

      true
    end

  private

    def teacher
      @teacher ||= induction_period.teacher
    end

    def record_admin_update_event(modifications)
      Events::Record.record_admin_updates_induction_period!(author:, modifications:, induction_period:, teacher: induction_period.teacher, appropriate_body: induction_period.appropriate_body)
    end

    def validate_can_update!
      raise RecordedOutcomeError, "Cannot edit induction period with recorded outcome" if induction_period.outcome.present?
    end

    def notify_trs_of_start_date_change(previous_start_date)
      return if induction_period.predecessors?
      return if previous_start_date == induction_period.started_on

      BeginECTInductionJob.perform_later(
        trn: teacher.trn,
        start_date: induction_period.started_on
      )
    end
  end
end
