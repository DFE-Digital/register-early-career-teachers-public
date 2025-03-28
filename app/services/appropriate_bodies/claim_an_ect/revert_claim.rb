module AppropriateBodies
  module ClaimAnECT
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

          # Only reset the induction status if this was the teacher's only induction period
          reset_induction_on_trs = teacher.induction_periods.count.zero?
          if reset_induction_on_trs
            ResetInductionJob.perform_later(trn: teacher.trn)
          end

          record_support_revert_teacher_claim_event!(author:, appropriate_body:, teacher:, reset_induction_on_trs:)
        end
      end

    private

      def record_support_revert_teacher_claim_event!(author:, appropriate_body:, teacher:, reset_induction_on_trs:)
        body = reset_induction_on_trs ? "Induction status was also reset on TRS." : nil
        Events::Record.record_support_revert_teacher_claim_event!(
          author:,
          appropriate_body:,
          teacher:,
          body:
        )
      end
    end
  end
end
