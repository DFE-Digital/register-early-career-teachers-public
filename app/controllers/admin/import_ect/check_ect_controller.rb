module Admin
  module ImportECT
    class CheckECTController < AdminController
      def edit
        @pending_induction_submission = find_pending_induction_submission
        @teacher = Teacher.find_by(trn: @pending_induction_submission.trn)
      end

      def update
        @pending_induction_submission = find_pending_induction_submission

        check_ect = Admin::ImportECT::CheckECT.new(
          pending_induction_submission: @pending_induction_submission
        )

        if check_ect.import
          redirect_to(admin_import_ect_register_path(check_ect.pending_induction_submission))
        else
          @pending_induction_submission = check_ect.pending_induction_submission
          render :edit
        end
      end

    private

      def find_pending_induction_submission
        PendingInductionSubmission.find(params[:id])
      end
    end
  end
end
