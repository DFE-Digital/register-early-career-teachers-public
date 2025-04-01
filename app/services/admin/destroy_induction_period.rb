module Admin
  class DestroyInductionPeriod
    attr_reader :author, :induction_period, :teacher, :appropriate_body

    def initialize(author:, induction_period:)
      @author = author
      @induction_period = induction_period
      @teacher = induction_period.teacher
      @appropriate_body = induction_period.appropriate_body
    end

    def destroy_induction_period!
      ActiveRecord::Base.transaction do
        modifications = induction_period.attributes
        induction_period.destroy!

        record_admin_deletes_induction_period!(
          author:,
          teacher:,
          appropriate_body:,
          modifications:
        )
      end
    end

  private

    def record_admin_deletes_induction_period!(author:, teacher:, appropriate_body:, modifications:)
      Events::Record.record_admin_deletes_induction_period!(
        author:,
        teacher:,
        appropriate_body:,
        modifications:
      )
    end
  end
end
