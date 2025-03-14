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
          steps = [
            update_name,
            update_qts_awarded_on,
            update_itt_provider_name,
            send_begin_induction_notification_to_trs,
            pending_induction_submission.save(context: :register_ect),
            create_induction_period
          ]

          steps.all? or raise ActiveRecord::Rollback
        end
      end

    private

      def update_name
        manage_teacher.update_name!(
          trs_first_name: pending_induction_submission.trs_first_name,
          trs_last_name: pending_induction_submission.trs_last_name
        )
      end

      def update_qts_awarded_on
        manage_teacher.update_qts_awarded_on!(
          trs_qts_awarded_on: pending_induction_submission.trs_qts_awarded_on
        )
      end

      def update_itt_provider_name
        manage_teacher.update_itt_provider_name!(
          trs_initial_teacher_training_provider_name: pending_induction_submission.trs_initial_teacher_training_provider_name
        )
      end

      def manage_teacher
        @manage_teacher ||= ::Teachers::Manage.find_or_initialize_by(
          trn: pending_induction_submission.trn,
          trs_first_name: pending_induction_submission.trs_first_name,
          trs_last_name: pending_induction_submission.trs_last_name,
          event_metadata: { author:, appropriate_body: }
        )
      end

      def teacher
        @manage_teacher.teacher
      end

      def create_induction_period
        started_on = pending_induction_submission.started_on
        induction_programme = pending_induction_submission.induction_programme

        @induction_period = InductionPeriods::CreateInductionPeriod
          .new(teacher:, started_on:, induction_programme:, appropriate_body:)
          .create_induction_period(author:)

        @induction_period.persisted?
      end

      def send_begin_induction_notification_to_trs
        return true if ::Teachers::Induction.new(teacher).has_induction_periods?

        BeginECTInductionJob.perform_later(
          trn: pending_induction_submission.trn,
          start_date: pending_induction_submission.started_on,
          pending_induction_submission_id: pending_induction_submission.id
        )
      end
    end
  end
end
