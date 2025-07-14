module Admin
  module ImportECT
    class FindECT
      attr_reader :pending_induction_submission

      def initialize(pending_induction_submission:)
        @pending_induction_submission = pending_induction_submission
      end

      def import_from_trs!
        return unless pending_induction_submission.valid?(:find_ect)

        pending_induction_submission.assign_attributes(
          **trs_teacher.present.except(:trs_national_insurance_number)
        )

        check_if_teacher_already_exists!
        trs_teacher.check_eligibility!
        check_admin_induction_eligibility!

        pending_induction_submission.save(context: :find_ect)
      end

    private

      def trs_teacher
        @trs_teacher ||= TRS::APIClient.build.find_teacher(
          trn: pending_induction_submission.trn,
          date_of_birth: pending_induction_submission.date_of_birth
        )
      end

      def check_if_teacher_already_exists!
        existing_teacher = Teacher.find_by(trn: pending_induction_submission.trn)

        return unless existing_teacher

        raise Admin::Errors::TeacherAlreadyExists, existing_teacher
      end

      def check_admin_induction_eligibility!
        induction_status = trs_teacher.induction_status

        if %w[Passed Failed Exempt].include?(induction_status)
          raise TRS::Errors::InductionAlreadyCompleted
        end
      end
    end
  end
end
