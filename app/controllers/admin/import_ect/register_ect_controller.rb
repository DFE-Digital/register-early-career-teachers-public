module Admin
  module ImportECT
    class RegisterECTController < AdminController
      def show
        @pending_induction_submission = find_pending_induction_submission

        register_ect = Admin::ImportECT::RegisterECT.new(
          pending_induction_submission: @pending_induction_submission,
          author: current_user
        )

        if register_ect.register
          @teacher = Teacher.find_by(trn: @pending_induction_submission.trn)
        else
          redirect_to edit_admin_import_ect_check_path(@pending_induction_submission), alert: "There was an error importing the teacher."
        end
      rescue Admin::Errors::TeacherAlreadyExists
        existing_teacher = Teacher.find_by(trn: @pending_induction_submission.trn)
        redirect_to(admin_teacher_path(existing_teacher), notice: "Teacher #{existing_teacher.trn} already exists in the system")
      end

    private

      def find_pending_induction_submission
        PendingInductionSubmission.find(params[:id])
      end
    end
  end
end
