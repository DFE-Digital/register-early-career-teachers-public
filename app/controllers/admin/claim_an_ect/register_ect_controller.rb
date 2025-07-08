module Admin
  module ClaimAnECT
    class RegisterECTController < AdminController
      before_action :set_appropriate_body
      def edit
        @pending_induction_submission = find_pending_induction_submission
      end

      def update
        register_ect = Admin::ClaimAnECT::RegisterECT
          .new(
            pending_induction_submission: find_pending_induction_submission,
            author: current_user
          )

        if register_ect.register(update_params)
          redirect_to(admin_appropriate_body_claim_an_ect_register_path(@appropriate_body, register_ect.pending_induction_submission))
        else
          @pending_induction_submission = register_ect.pending_induction_submission

          render(:edit)
        end
      end

      def show
        @pending_induction_submission = find_pending_induction_submission
      end

    private

      def update_params
        params.require(:pending_induction_submission).permit(:started_on, :finished_on, :induction_programme, :trs_induction_status, :appropriate_body_id, :number_of_terms)
      end

      def find_pending_induction_submission
        PendingInductionSubmission.find(params[:id])
      end

      def set_appropriate_body
        @appropriate_body = AppropriateBody.find(params[:appropriate_body_id])
      end
    end
  end
end
