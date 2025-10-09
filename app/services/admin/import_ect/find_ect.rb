module Admin
  module ImportECT
    class FindECT
      attr_reader :api_client, :pending_induction_submission

      def initialize(pending_induction_submission:)
        @api_client = TRS::APIClient.build
        @pending_induction_submission = pending_induction_submission
      end

      # @raise [TRS::Errors::TeacherDeactivated]
      # @raise [TRS::Errors::TeacherNotFound]
      # @raise [TRS::Errors::ProhibitedFromTeaching]
      # @raise [TRS::Errors::InductionAlreadyCompleted]
      # @raise [TRS::Errors::QTSNotAwarded]
      # @raise [AppropriateBodies::Errors::TeacherHasActiveInductionPeriodWithCurrentAB]
      #
      # @return [Boolean]
      def import_from_trs!
        return false unless pending_induction_submission.valid?(:find_ect)

        pending_induction_submission.assign_attributes(
          **trs_teacher.to_h.except(:trs_national_insurance_number, :trs_induction_completed_date)
        )

        check_if_teacher_already_exists!

        trs_teacher.check_eligibility!

        pending_induction_submission.save(context: :find_ect)
      end

    private

      # @return [TRS::Teacher]
      def trs_teacher
        @trs_teacher ||= api_client.find_teacher(
          trn: pending_induction_submission.trn,
          date_of_birth: pending_induction_submission.date_of_birth
        )
      end

      # @raise [Admin::Errors::TeacherAlreadyExists]
      # @return [nil]
      def check_if_teacher_already_exists!
        existing_teacher = Teacher.find_by(trn: pending_induction_submission.trn)

        return unless existing_teacher

        raise Admin::Errors::TeacherAlreadyExists, existing_teacher
      end
    end
  end
end
