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

      ActiveRecord::Base.transaction do
        induction_period.update!(params)
        notify_trs_of_start_date_change
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

    def notify_trs_of_start_date_change
      return if ect_has_earlier_induction_periods?

      BeginECTInductionJob.perform_later(
        trn: teacher.trn,
        start_date: induction_period.started_on
      )
    end

    def ect_has_earlier_induction_periods?
      InductionPeriod
        .siblings_of(induction_period)
        .started_before(induction_period.started_on)
        .exists?
    end
  end
end
