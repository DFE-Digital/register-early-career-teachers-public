module Admin
  class DestroyInductionPeriod
    attr_reader :author, :induction_period, :teacher, :appropriate_body_period

    def initialize(author:, induction_period:)
      @author = author
      @induction_period = induction_period
      @teacher = induction_period.teacher
      @appropriate_body_period = induction_period.appropriate_body_period
    end

    def destroy_induction_period!
      ActiveRecord::Base.transaction do
        modifications = induction_period.attributes
        induction_period.destroy!

        Events::Record.record_induction_period_deleted_event!(
          author:,
          teacher:,
          appropriate_body_period:,
          modifications:
        )
      end
    end
  end
end
