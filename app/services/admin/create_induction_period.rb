module Admin
  class CreateInductionPeriod
    attr_reader :induction_period, :author, :induction_period_params, :appropriate_body_id, :teacher_id

    def initialize(author:, appropriate_body_id:, teacher_id:, started_on:, induction_programme:, finished_on: nil, number_of_terms: nil)
      @author = author

      @appropriate_body_id = appropriate_body_id
      @teacher_id = teacher_id
      @induction_period_params = {
        started_on:,
        finished_on:,
        induction_programme:,
        number_of_terms:,
      }
    end

    def create_induction_period!
      build_induction_period.tap do |induction_period|
        ActiveRecord::Base.transaction do
          modifications = induction_period.changes
          success = [
            induction_period.save,
            record_event(modifications),
            notify_trs_of_new_induction_start
          ].all?

          success or raise ActiveRecord::Rollback
        end
      end
    end

  private

    def build_induction_period
      @induction_period = InductionPeriod.new(appropriate_body:, teacher:, **induction_period_params)
    end

    def teacher
      @teacher ||= Teacher.find(teacher_id)
    end

    def appropriate_body
      @appropriate_body ||= AppropriateBody.find(appropriate_body_id)
    end

    def record_event(modifications)
      return unless induction_period.persisted?

      Events::Record.record_admin_creates_induction_period!(author:, modifications:, induction_period:, teacher:, appropriate_body:, happened_at: Time.zone.now)
    end

    # FIXME: there's no separate way to inform TRS of a new induction start date
    #        so we're reusing the BeginECTInductionJob here. We need to make sure
    #        we don't create induction periods for ECTs who have already passed/failed
    def notify_trs_of_new_induction_start
      return if teacher_has_earlier_induction_periods?

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
