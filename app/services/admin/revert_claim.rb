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
        Admin::DestroyInductionPeriod.new(
          author:,
          induction_period:
        ).destroy_induction_period!

        # Only reset the induction status if this was the teacher's only induction period
        if teacher.induction_periods.count.zero?
          ResetInductionJob.perform_later(trn: teacher.trn)
          record_admin_reverts_teacher_claim_event!
        end
      end
    end

  private

    def record_admin_reverts_teacher_claim_event!
      Events::Record.record_admin_reverts_teacher_claim_event!(
        author:,
        appropriate_body:,
        teacher:
      )
    end
  end
end
