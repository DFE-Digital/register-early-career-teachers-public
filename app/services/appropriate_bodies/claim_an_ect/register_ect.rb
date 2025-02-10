# https://github.com.mcas.ms/DFE-Digital/register-ects-project-board/issues/1039

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
            # create_or_update_teacher,
            manage_teacher.create_or_update!,
            record_name_change_event,
            # record_award_change_event,

            send_begin_induction_notification_to_trs,
            pending_induction_submission.save(context: :register_ect),
            create_induction_period
          ]

          steps.all? or raise ActiveRecord::Rollback
        end
      end

    private

      def record_name_change_event
        return true unless manage_teacher.name_changed?

        Events::Record.teacher_name_changed_in_trs!(author:, teacher:, appropriate_body:, **manage_teacher.changed_names)
      end

      def record_award_change_event
        true unless manage_teacher.qts_awarded_on_changed?

        # Events::Record.qts_awarded_on_changed_in_trs!(author:, teacher:, appropriate_body:, **manage_teacher.changed_qts_awarded_on)
      end

      # def create_or_update_teacher
      #   # separate methods
      #   # manage
      #   #   .set_trs_name(pending_induction_submission.trs_first_name, pending_induction_submission.trs_last_name)
      #   #   .set_trs_qts_awarded_on(pending_induction_submission.trs_qts_awarded_on)

      #   # combined method
      #   manage.create_or_update
      #   record_name_change_event
      #   true
      # end

      def manage_teacher
        @manage_teacher ||= ::Teachers::Manage.new(pending_induction_submission)
      end

      def teacher
        manage_teacher.teacher
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
        BeginECTInductionJob.perform_later(
          trn: pending_induction_submission.trn,
          start_date: pending_induction_submission.started_on.to_s,
          pending_induction_submission_id: pending_induction_submission.id
        )
      end
    end
  end
end
