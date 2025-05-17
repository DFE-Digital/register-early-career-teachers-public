module InductionPeriods
  class CreateInductionPeriod
    attr_reader :induction_period,
                :event,
                :params,
                :teacher,
                :author

    # @param author [Sessions::User]
    # @param teacher [Teacher]
    # @param params [ActionController::Parameters]
    def initialize(author:, teacher:, params:)
      @author = author
      @teacher = teacher
      @params = params
      @induction_period = InductionPeriod.new(params.merge(teacher:))
    end

    # @return [InductionPeriod]
    # @raise [ActiveRecord::RecordInvalid, ActiveRecord::Rollback]
    def create_induction_period!
      raise ActiveRecord::RecordInvalid, @induction_period unless @induction_period.valid?

      ActiveRecord::Base.transaction do
        @induction_period.save!
        record_event or raise ActiveRecord::Rollback
      end

      notify_trs_of_new_induction_start if notify_trs?

      @induction_period
    end

  private

    # @return [Boolean]
    def record_event
      return false unless @induction_period.persisted?

      Events::Record.record_induction_period_opened_event!(
        author: @author,
        teacher: @teacher,
        appropriate_body: @induction_period.appropriate_body,
        induction_period: @induction_period,
        modifications: @induction_period.changes
      )

      true
    end

    def notify_trs?
      # Only notify TRS if this is the earliest induction period for the teacher
      # and the teacher hasn't already passed or failed induction
      !teacher_has_earlier_induction_periods? && !teacher_has_passed_or_failed_induction?
    end

    def teacher_has_earlier_induction_periods?
      InductionPeriod.where(teacher:).started_before(params[:started_on]).exists?
    end

    def teacher_has_passed_or_failed_induction?
      # Check if the teacher has any induction periods with a pass or fail outcome
      InductionPeriod.where(teacher:, outcome: InductionPeriod::OUTCOMES).exists?
    end

    def notify_trs_of_new_induction_start
      BeginECTInductionJob.perform_later(
        trn: teacher.trn,
        start_date: params[:started_on]
      )
    end
  end
end
