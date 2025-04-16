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
  end
end
