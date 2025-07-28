module InductionPeriods
  class UpdateInductionPeriod
    class RecordedOutcomeError < StandardError; end

    attr_reader :author, :induction_period, :params

    # @param author [Sessions::User]
    # @param induction_period [InductionPeriod]
    # @param params [ActionController::Parameters]
    def initialize(author:, induction_period:, params:)
      @author = author
      @induction_period = induction_period
      @params = params
    end

    # @return [true]
    # @raise [ActiveRecord::RecordInvalid, ActiveRecord::Rollback]
    def update_induction_period!
      previous_start_date = induction_period.started_on
      previous_end_date = induction_period.finished_on

      induction_period.assign_attributes(params)

      # Transition induction programme to the new training programme values
      if Rails.application.config.enable_bulk_claim
        induction_programme = ::PROGRAMME_MAPPER[params[:training_programme]]
        induction_period.assign_attributes(induction_programme:) if induction_period.induction_programme.blank?
      else
        training_programme = ::PROGRAMME_MAPPER[params[:induction_programme]]
        induction_period.assign_attributes(training_programme:)
      end

      modifications = induction_period.changes

      # Prevent setting dates to nil for induction periods with outcomes
      if induction_period.outcome.present? && params.key?(:finished_on) && params[:finished_on].nil?
        raise ActiveRecord::RecordInvalid.new(induction_period), "End date cannot be set to nil for induction periods with outcomes"
      end

      ActiveRecord::Base.transaction do
        induction_period.save!
        record_induction_period_update_event(modifications)
        handle_trs_notifications(previous_start_date, previous_end_date)
      end

      true
    end

  private

    delegate :teacher, :appropriate_body, to: :induction_period

    # @param modifications [Hash{String => Array}]
    def record_induction_period_update_event(modifications)
      Events::Record.record_induction_period_updated_event!(
        author:,
        modifications:,
        induction_period:,
        teacher:,
        appropriate_body:
      )
    end

    def handle_trs_notifications(previous_start_date, previous_end_date)
      start_date_changed = previous_start_date != induction_period.started_on
      end_date_changed = previous_end_date != induction_period.finished_on

      if induction_period.outcome.blank?
        if start_date_changed
          is_earliest_period = teacher.induction_periods.earliest_first.first == induction_period
          if is_earliest_period && induction_period.finished_on.nil?
            BeginECTInductionJob.perform_later(
              trn: teacher.trn,
              start_date: induction_period.started_on
            )
            record_teacher_trs_induction_start_date_updated_event!
          end
        end
      else
        if end_date_changed
          send_pass_or_fail_notification
          record_teacher_trs_induction_end_date_updated_event!
        end

        if start_date_changed
          record_teacher_trs_induction_start_date_updated_event!
        end
      end
    end

    def record_teacher_trs_induction_start_date_updated_event!
      Events::Record.record_teacher_trs_induction_start_date_updated_event!(
        author:,
        teacher:,
        appropriate_body:,
        induction_period:
      )
    end

    def record_teacher_trs_induction_end_date_updated_event!
      Events::Record.record_teacher_trs_induction_end_date_updated_event!(
        author:,
        teacher:,
        appropriate_body:,
        induction_period:
      )
    end

    def send_pass_or_fail_notification
      @pass_or_fail_notification_sent = true
      if induction_period.outcome == "pass"
        PassECTInductionJob.perform_later(
          trn: teacher.trn,
          start_date: induction_period.started_on,
          completed_date: induction_period.finished_on,
          pending_induction_submission_id: nil
        )
      elsif induction_period.outcome == "fail"
        FailECTInductionJob.perform_later(
          trn: teacher.trn,
          start_date: induction_period.started_on,
          completed_date: induction_period.finished_on,
          pending_induction_submission_id: nil
        )
      end
    end
  end
end
