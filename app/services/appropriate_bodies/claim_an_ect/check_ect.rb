module AppropriateBodies
  module ClaimAnECT
    class CheckECT
      attr_reader :appropriate_body, :pending_induction_submission, :confirmed

      def initialize(appropriate_body:, pending_induction_submission:)
        @appropriate_body = appropriate_body
        @pending_induction_submission = pending_induction_submission
      end

      def confirm_info_correct(confirmed)
        check_if_teacher_has_active_induction_period_with_another_appropriate_body!

        pending_induction_submission.tap do |submission|
          submission.confirmed = confirmed
          submission.confirmed_at = Time.zone.now if confirmed
        end

        pending_induction_submission.save(context: :check_ect)
      end

    private

      def check_if_teacher_has_active_induction_period_with_another_appropriate_body!
        existing_teacher = Teacher.find_by(trn: pending_induction_submission.trn)

        return unless existing_teacher

        active_induction_period = ::Teachers::InductionPeriod.new(existing_teacher).active_induction_period

        return unless active_induction_period

        if active_induction_period.appropriate_body != appropriate_body
          raise AppropriateBodies::Errors::TeacherHasActiveInductionPeriodWithAnotherAB, ::Teachers::Name.new(existing_teacher).full_name
        end
      end
    end
  end
end
