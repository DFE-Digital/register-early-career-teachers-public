module Admin
  class CheckTeacherController < AdminController
    def edit
      @pending_induction_submission = find_pending_induction_submission
    end

    def update
      @pending_induction_submission = find_pending_induction_submission

      check_teacher_service = Admin::CheckTeacher.new(
        pending_induction_submission: @pending_induction_submission,
        author: current_user
      )

      if check_teacher_service.import_teacher!
        redirect_to(admin_teachers_path, notice: "Teacher successfully imported from TRS")
      else
        render :edit
      end
    end

  private

    def find_pending_induction_submission
      PendingInductionSubmission.find(params[:id])
    end
  end
end
