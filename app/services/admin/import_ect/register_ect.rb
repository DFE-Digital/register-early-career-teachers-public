module Admin
  module ImportECT
    class RegisterECT
      attr_reader :pending_induction_submission, :author

      def initialize(pending_induction_submission:, author:)
        @pending_induction_submission = pending_induction_submission
        @author = author
      end

      def register
        ActiveRecord::Base.transaction do
          check_if_teacher_already_exists!

          manage_teacher = ::Teachers::Manage.find_or_initialize_by(
            trn: pending_induction_submission.trn,
            trs_first_name: pending_induction_submission.trs_first_name,
            trs_last_name: pending_induction_submission.trs_last_name,
            event_metadata: { author:, appropriate_body: nil }
          )

          @teacher = manage_teacher.teacher
        end
      end

    private

      def check_if_teacher_already_exists!
        existing_teacher = Teacher.find_by(trn: pending_induction_submission.trn)

        if existing_teacher
          raise Admin::Errors::TeacherAlreadyExists, ::Teachers::Name.new(existing_teacher).full_name
        end
      end
    end
  end
end
