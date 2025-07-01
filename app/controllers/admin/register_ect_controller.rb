module Admin
  class RegisterECTController < AdminController
    def new
      @pending_induction_submission = PendingInductionSubmission.new
    end

    def create
      find_ect = ::Admin::FindECT.new(
        pending_induction_submission: PendingInductionSubmission.new(**pending_induction_submission_params)
      )
      @pending_induction_submission = find_ect.pending_induction_submission

      if find_ect.import_from_trs!
        redirect_to(edit_admin_check_teacher_path(@pending_induction_submission))
      else
        render(:new)
      end
    rescue TRS::Errors::QTSNotAwarded
      @pending_induction_submission.save!
      redirect_to admin_errors_no_qts_path(@pending_induction_submission)
    rescue TRS::Errors::ProhibitedFromTeaching
      @pending_induction_submission.save!
      redirect_to admin_errors_prohibited_path(@pending_induction_submission)
    rescue TRS::Errors::TeacherNotFound, TRS::Errors::TeacherDeactivated
      @pending_induction_submission.errors.add(:base, "No teacher with this TRN and date of birth was found")
      render(:new)
    rescue ::AppropriateBodies::Errors::TeacherAlreadyExists
      @pending_induction_submission.save!
      redirect_to admin_errors_already_exists_path(@pending_induction_submission)
    rescue ::TRS::Errors::InductionStatusInvalid
      @pending_induction_submission.save!
      redirect_to admin_errors_induction_status_invalid_path(@pending_induction_submission)
    end

  private

    def pending_induction_submission_params
      params.require(:pending_induction_submission).permit(:trn, :date_of_birth)
    end
  end
end
