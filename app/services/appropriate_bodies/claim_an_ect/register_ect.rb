module AppropriateBodies
  module ClaimAnECT
    class RegisterECT
      attr_reader :appropriate_body, :pending_induction_submission, :induction_period, :author

      def initialize(appropriate_body:, pending_induction_submission:, author:)
        @appropriate_body = appropriate_body
        @pending_induction_submission = pending_induction_submission
        @author = author
      end

      def register(pending_induction_submission_params)
        pending_induction_submission.assign_attributes(**pending_induction_submission_params)

        # FIXME: I think the behaviour here should be to still allow the AB to claim
        #        the ECT, but we shouldn't report the starting of induction to TRS
        # if teacher.persisted? && teacher.induction_periods.present?
        #   raise AppropriateBodies::Errors::TeacherAlreadyClaimedError, "Teacher already claimed"
        # end

        ActiveRecord::Base.transaction do
          success = (
            update_teacher &&
            create_induction_period &&
            send_begin_induction_notification_to_trs &&
            pending_induction_submission.save(context: :register_ect) &&
            record_claim_event
          )

          success or raise ActiveRecord::Rollback
        end
      end

    private

      def update_teacher
        old_name = ::Teachers::Name.new(teacher).full_name_in_trs

        teacher.assign_attributes(
          first_name: pending_induction_submission.trs_first_name,
          last_name: pending_induction_submission.trs_last_name,
          qts_awarded_on: pending_induction_submission.trs_qts_awarded
        )

        new_name = ::Teachers::Name.new(teacher).full_name_in_trs

        teacher.save!

        if new_name != old_name
          Events::Record.teacher_name_changed_in_trs!(author:, old_name:, new_name:, teacher:, appropriate_body:)
        end

        true
      end

      def teacher
        @teacher ||= Teacher.find_or_initialize_by(trn: pending_induction_submission.trn)
      end

      def create_induction_period
        @induction_period = InductionPeriod.create(
          teacher:,
          started_on: pending_induction_submission.started_on,
          appropriate_body:,
          induction_programme: pending_induction_submission.induction_programme
        )
      end

      def record_claim_event
        Events::Record.record_appropriate_body_claims_teacher_event!(
          author:,
          teacher:,
          appropriate_body:,
          induction_period:
        )
      end

      def send_begin_induction_notification_to_trs
        BeginECTInductionJob.perform_later(
          trn: pending_induction_submission.trn,
          start_date: pending_induction_submission.started_on.to_s,
          teacher_id: teacher.id,
          pending_induction_submission_id: pending_induction_submission.id
        )
      end
    end
  end
end
