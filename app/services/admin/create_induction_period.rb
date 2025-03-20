module Admin
  class CreateInductionPeriod
    attr_reader :author, :teacher, :induction_period

    # @param author [Sessions::User]
    # @param teacher [Teacher]
    # @param params [ActionController::Parameters]
    def initialize(author:, teacher:, params:)
      @author = author
      @teacher = teacher
      @induction_period = InductionPeriod.new(teacher:, **params)
    end

    # @return [true]
    # @raise [ActiveRecord::RecordInvalid, ActiveRecord::Rollback]
    def create_induction_period!
      modifications = induction_period.changes

      ActiveRecord::Base.transaction do
        success = [
          induction_period.save!,
          record_event(modifications),
          notify_trs_of_new_induction_start
        ].all?

        success or raise ActiveRecord::Rollback
      end
    end

  private

    delegate :appropriate_body, to: :induction_period

    # @param modifications [Hash{String => Array}]
    def record_event(modifications)
      return unless induction_period.persisted?

      Events::Record.record_admin_creates_induction_period!(
        author:,
        modifications:,
        induction_period:,
        teacher:,
        appropriate_body:,
        happened_at: Time.zone.now
      )
    end

    # FIXME: there's no separate way to inform TRS of a new induction start date
    #        so we're reusing the BeginECTInductionJob here. We need to make sure
    #        we don't create induction periods for ECTs who have already passed/failed
    def notify_trs_of_new_induction_start
      return true if teacher_has_earlier_induction_periods?

      BeginECTInductionJob.perform_later(
        trn: teacher.trn,
        start_date: induction_period.started_on
      )
    end

    def teacher_has_earlier_induction_periods?
      InductionPeriod.where(teacher:).started_before(induction_period.started_on).exists?
    end
  end
end
