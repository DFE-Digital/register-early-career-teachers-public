module AppropriateBodies
  module ClaimAnECT
    class CheckECTController < AppropriateBodiesController
      def edit
        @current_appropriate_body = current_user.appropriate_body
        @pending_induction_submission = find_pending_induction_submission
        @teacher = Teacher.find_by(trn: @pending_induction_submission.trn)
      end

      def update
        @pending_induction_submission = find_pending_induction_submission

        check_ect = AppropriateBodies::ClaimAnECT::CheckECT
          .new(appropriate_body: @appropriate_body, pending_induction_submission: @pending_induction_submission)

        if check_ect.begin_claim!
          redirect_to(edit_ab_claim_an_ect_register_path(check_ect.pending_induction_submission))
        else
          @pending_induction_submission = check_ect.pending_induction_submission

          render :edit
        end
      rescue AppropriateBodies::Errors::TeacherHasActiveInductionPeriodWithAnotherAB
        redirect_to ab_claim_an_ect_errors_another_ab_path(@pending_induction_submission)
      end

    private

      def find_pending_induction_submission
        PendingInductionSubmissions::Search.new(appropriate_body: @appropriate_body).pending_induction_submissions.find(params[:id])
      end
    end
  end
end
