module Admin
  class UpdateInductionPeriodService
    class RecordedOutcomeError < StandardError; end

    attr_reader :induction_period, :params

    def initialize(induction_period:, params:)
      @induction_period = induction_period
      @params = params
    end

    def update_induction!
      validate_can_update!

      previous_start_date = induction_period.started_on

      ActiveRecord::Base.transaction do
        induction_period.update!(params)
        notify_trs_of_start_date_change(previous_start_date)
      end

      true
    end

  private

    def teacher
      @teacher ||= induction_period.teacher
    end

    def validate_can_update!
      raise RecordedOutcomeError, "Cannot edit induction period with recorded outcome" if induction_period.outcome.present?
    end

    def notify_trs_of_start_date_change(previous_start_date)
      return unless earliest_period? && previous_start_date != induction_period.started_on

      BeginECTInductionJob.perform_later(
        trn: teacher.trn,
        start_date: induction_period.started_on,
        teacher_id: teacher.id
      )
    end

    def earliest_period?
      !InductionPeriod.where(teacher: teacher)
        .where("started_on < ?", induction_period.started_on)
        .exists?
    end
  end
end
