module Admin
  class DeleteInductionPeriod
    attr_reader :author, :induction_period, :teacher

    # @param author [Sessions::User]
    # @param induction_period [InductionPeriod]
    def initialize(author:, induction_period:)
      @author = author
      @induction_period = induction_period
      @teacher = induction_period.teacher
    end

    # @return [true]
    # @raise [ActiveRecord::RecordInvalid, ActiveRecord::Rollback]
    def delete_induction_period!
      modifications = induction_period.attributes.transform_values { |v| [v, nil] }
      appropriate_body = induction_period.appropriate_body

      ActiveRecord::Base.transaction do
        induction_period.destroy!
        record_event(modifications, appropriate_body)
        reset_trs_if_needed
      end

      true
    end

  private

    def reset_trs_if_needed
      if teacher.induction_periods.reload.none?
        TRS::APIClient.new.reset_teacher_induction(trn: teacher.trn)
      end
    end

    def record_event(modifications, appropriate_body)
      Events::Record.record_induction_period_deleted_event!(
        author:,
        modifications:,
        teacher:,
        appropriate_body:,
        happened_at: Time.zone.now
      )
    end
  end
end
