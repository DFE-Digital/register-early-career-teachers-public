module Admin
  class RevertClaim
    attr_reader :appropriate_body, :teacher, :author, :induction_period

    def initialize(appropriate_body:, teacher:, author:, induction_period:)
      @appropriate_body = appropriate_body
      @teacher = teacher
      @author = author
      @induction_period = induction_period
    end

    def revert_claim
      ActiveRecord::Base.transaction do
        induction_period.destroy!

        record_admin_deletes_induction_period!(author:, appropriate_body:, teacher:)

        # Only reset the induction status if this was the teacher's only induction period
        if teacher.induction_periods.count.zero?
          ResetInductionJob.perform_later(trn: teacher.trn)
          record_admin_reverts_teacher_claim_event!(author:, appropriate_body:, teacher:)
        end
      end
    end

  private

    def record_admin_reverts_teacher_claim_event!(author:, appropriate_body:, teacher:)
      Events::Record.record_admin_reverts_teacher_claim_event!(
        author:,
        appropriate_body:,
        teacher:
      )
    end

    def record_admin_deletes_induction_period!(author:, appropriate_body:, teacher:)
      Events::Record.record_admin_deletes_induction_period!(
        author:,
        teacher:,
        appropriate_body:,
        modifications: induction_period.attributes
      )
    end
  end
end
