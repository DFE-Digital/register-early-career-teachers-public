module Admin
  class ErrorsController < AdminController
    def already_exists
      @pending_induction_submission = find_pending_induction_submission
    end

    def induction_status_invalid
      @pending_induction_submission = find_pending_induction_submission
    end

    def no_qts
      @pending_induction_submission = find_pending_induction_submission
    end

    def prohibited_from_teaching
      @pending_induction_submission = find_pending_induction_submission
    end

  private

    def find_pending_induction_submission
      PendingInductionSubmission.find(params[:id])
    end
  end
end
