module Admin
  class CreateInductionPeriod
    attr_reader :author, :teacher, :induction_period, :params

    # @param author [Sessions::User]
    # @param teacher [Teacher]
    # @param params [ActionController::Parameters]
    def initialize(author:, teacher:, params:)
      @author = author
      @teacher = teacher
      @params = params
    end

    # @return [true]
    # @raise [ActiveRecord::RecordInvalid, ActiveRecord::Rollback]
    def create_induction_period!
      @induction_period = InductionPeriods::CreateInductionPeriod.new(
        author:,
        teacher:,
        params:
      ).create_induction_period!

      notify_trs_of_new_induction_start if notify_trs?

      true
    end

  private

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
