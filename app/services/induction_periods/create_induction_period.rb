module InductionPeriods
  class CreateInductionPeriod
    attr_reader :induction_period,
                :event,
                :teacher,
                :author

    # @param author [Sessions::User]
    # @param teacher [Teacher]
    # @param params [ActionController::Parameters]
    def initialize(author:, teacher:, params:)
      @author = author
      @teacher = teacher
      @induction_period = InductionPeriod.new(params.merge(teacher:))
    end

    # @return [InductionPeriod]
    # @raise [ActiveRecord::RecordInvalid, ActiveRecord::Rollback]
    def create_induction_period!
      raise ActiveRecord::RecordInvalid, induction_period unless induction_period.valid?

      ActiveRecord::Base.transaction do
        induction_period.save!
        record_event or raise ActiveRecord::Rollback
        update_school_reported_appropriate_body!
      end

      set_eligibility_for_funding!

      if teacher.induction_periods.started_before(induction_period.started_on)
          .or(teacher.induction_periods.with_outcome)
          .none?
        notify_trs_of_new_induction_start
      end

      induction_period
    end

  private

    # @return [Boolean]
    def record_event
      return false unless induction_period.persisted?

      Events::Record.record_induction_period_opened_event!(
        author:,
        teacher:,
        appropriate_body_period: induction_period.appropriate_body_period,
        induction_period:,
        modifications: induction_period.changes
      )

      true
    end

    def update_school_reported_appropriate_body!
      ect_at_school_period = teacher.ect_at_school_periods.current_or_future.earliest_first.first
      return if ect_at_school_period.nil?

      new_appropriate_body_period = induction_period.appropriate_body_period
      return if ect_at_school_period.school_reported_appropriate_body_id == new_appropriate_body_period.id

      old_appropriate_body_name = ect_at_school_period.school_reported_appropriate_body_name

      ect_at_school_period.update!(school_reported_appropriate_body: new_appropriate_body_period)

      Events::Record.record_school_reported_appropriate_body_updated_event!(
        author:,
        teacher:,
        ect_at_school_period:,
        appropriate_body_period: new_appropriate_body_period,
        old_appropriate_body_name:
      )
    end

    def notify_trs_of_new_induction_start
      BeginECTInductionJob.perform_later(
        trn: teacher.trn,
        start_date: induction_period.started_on
      )
    end

    def set_eligibility_for_funding!
      Teachers::SetECTFundingEligibility.new(
        teacher:,
        author:
      ).set!
    end
  end
end
