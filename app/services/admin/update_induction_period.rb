module Admin
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
      validate_can_update!

      previous_start_date = induction_period.started_on
      induction_period.assign_attributes(params)
      modifications = induction_period.changes

      ActiveRecord::Base.transaction do
        success = [
          induction_period.save!,
          record_event(modifications),
          notify_trs_of_start_date_change(previous_start_date)
        ].all?

        success or raise ActiveRecord::Rollback
      end
    end

  private

    delegate :teacher, :appropriate_body, to: :induction_period

    # @param modifications [Hash{String => Array}]
    def record_event(modifications)
      return unless induction_period.persisted?

      Events::Record.record_admin_updates_induction_period!(
        author:,
        modifications:,
        induction_period:,
        teacher:,
        appropriate_body:
      )
    end

    def validate_can_update!
      raise RecordedOutcomeError, "Cannot edit induction period with recorded outcome" if induction_period.outcome.present?
    end

    def notify_trs_of_start_date_change(previous_start_date)
      return true if induction_period.has_predecessors?
      return true if previous_start_date == induction_period.started_on

      BeginECTInductionJob.perform_later(
        trn: teacher.trn,
        start_date: induction_period.started_on
      )
    end
  end
end
