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
            create_or_update_teacher,
            send_begin_induction_notification_to_trs,
            pending_induction_submission.save(context: :register_ect),
            create_induction_period
          ]

          steps.all? or raise ActiveRecord::Rollback
        end
      end

    private

      # FIXME: move this to its own service class
      def create_or_update_teacher
        old_name = ::Teachers::Name.new(teacher).full_name_in_trs

        teacher.assign_attributes(
          trs_first_name: pending_induction_submission.trs_first_name,
          trs_last_name: pending_induction_submission.trs_last_name,
          trs_qts_awarded_on: pending_induction_submission.trs_qts_awarded_on
        )

        new_name = ::Teachers::Name.new(teacher).full_name_in_trs

        teacher.save!

        if old_name && new_name != old_name
          Events::Record.teacher_name_changed_in_trs!(author:, old_name:, new_name:, teacher:, appropriate_body:)
        end

        true
      end

      def teacher
        @teacher ||= Teacher.find_or_initialize_by(trn: pending_induction_submission.trn)
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
          start_date: pending_induction_submission.started_on,
          pending_induction_submission_id: pending_induction_submission.id
        )
      end
    end
  end
end
