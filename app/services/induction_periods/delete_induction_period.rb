module InductionPeriods
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
      if induction_period.outcome.present?
        raise ActiveRecord::RecordInvalid, induction_period
      end

      modifications = induction_period.attributes.transform_values { |v| [v, nil] }
      appropriate_body = induction_period.appropriate_body
      was_only_induction_period = teacher.induction_periods.where.not(id: induction_period.id).empty?
      is_earliest_period = induction_period == teacher.induction_periods.earliest_first.first

      ActiveRecord::Base.transaction do
        induction_period.destroy!

        if was_only_induction_period
          # If this was the only induction period, reset TRS status
          reset_trs_status
          record_trs_status_reset_event(appropriate_body)
        elsif is_earliest_period
          # If this was the earliest period but there are others, update TRS start date
          next_earliest_period = teacher.induction_periods.reload.earliest_first.first
          update_trs_start_date(next_earliest_period)
          record_teacher_trs_induction_start_date_updated_event(appropriate_body, next_earliest_period)
        end

        record_delete_event(modifications, appropriate_body)
      end

      true
    end

  private

    def update_trs_start_date(next_earliest_period)
      TRS::APIClient.build.begin_induction!(
        trn: teacher.trn,
        start_date: next_earliest_period.started_on
      )
    end

    def reset_trs_status
      TRS::APIClient.build.reset_teacher_induction!(trn: teacher.trn)
    end

    def record_teacher_trs_induction_start_date_updated_event(appropriate_body, induction_period)
      Events::Record.record_teacher_trs_induction_start_date_updated_event!(
        author:,
        teacher:,
        appropriate_body:,
        induction_period:
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

    def record_trs_status_reset_event(appropriate_body)
      Events::Record.record_teacher_induction_status_reset_event!(
        author:,
        teacher:,
        appropriate_body:,
        happened_at: Time.zone.now
      )
    end
  end
end
