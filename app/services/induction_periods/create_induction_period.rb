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
      end

      set_eligibility!

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
        appropriate_body: induction_period.appropriate_body,
        induction_period:,
        modifications: induction_period.changes
      )

      true
    end

    def set_eligibility!
      if teacher.eligible_for_mentor_training?
        teacher.first_became_eligible_for_mentor_training_at ||= Time.zone.now
      end

      if teacher.eligible_for_ect_training?
        teacher.first_became_eligible_for_ect_training_at ||= Time.zone.now
      end

      teacher.save!
    end

    def notify_trs_of_new_induction_start
      BeginECTInductionJob.perform_later(
        trn: teacher.trn,
        start_date: induction_period.started_on
      )
    end
  end
end
