module Admin
  module ClaimAnECT
    class CheckECTController < AdminController
      before_action :set_appropriate_body
      def edit
        @pending_induction_submission = find_pending_induction_submission
        @teacher = Teacher.find_by(trn: @pending_induction_submission.trn)
      end

      def update
        @pending_induction_submission = find_pending_induction_submission

        check_ect = Admin::ClaimAnECT::CheckECT
          .new(pending_induction_submission: @pending_induction_submission)

        if check_ect.begin_claim!
          redirect_to(edit_admin_appropriate_body_claim_an_ect_register_path(@appropriate_body, check_ect.pending_induction_submission))
        else
          @pending_induction_submission = check_ect.pending_induction_submission

          render :edit
        end
      rescue Admin::Errors::TeacherHasActiveInductionPeriodWithAnotherAB
        redirect_to admin_appropriate_body_claim_an_ect_errors_another_ab_path(@appropriate_body, @pending_induction_submission)
      end

    private

      def find_pending_induction_submission
        PendingInductionSubmission.find(params[:id])
      end

      def set_appropriate_body
        @appropriate_body = AppropriateBody.find(params[:appropriate_body_id])
      end
    end
  end
end
