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
      has_other_periods = teacher.induction_periods.where.not(id: induction_period.id).exists?

      ActiveRecord::Base.transaction do
        # Store the induction period ID before destroying
        induction_period_id = induction_period.id

        induction_period.destroy!

        if has_other_periods
          update_trs_start_date
          record_update_event(modifications, appropriate_body)
        else
          reset_trs_status
          record_delete_event(modifications, appropriate_body)
        end
      end

      true
    end

  private

    def update_trs_start_date
      next_earliest_period = teacher.induction_periods.reload.earliest_first.first
      TRS::APIClient.new.begin_induction!(
        trn: teacher.trn,
        start_date: next_earliest_period.started_on
      )
    end

    def reset_trs_status
      TRS::APIClient.new.reset_teacher_induction(trn: teacher.trn)
    end

    def record_update_event(modifications, appropriate_body)
      Events::Record.record_induction_period_updated_event!(
        author:,
        modifications:,
        teacher:,
        appropriate_body:,
        happened_at: Time.zone.now
      )
    end

    def record_delete_event(modifications, appropriate_body)
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
