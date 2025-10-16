module Admin
  module Teachers
    class RecordPassedInductionController < CloseInductionController
      def create
        if @teacher.ongoing_induction_period.present?
          @pending_induction_submission = build_closing_induction_period(outcome: "pass")

          PendingInductionSubmission.transaction do
            if @pending_induction_submission.save(context: :record_outcome) && record_passed_induction!
              redirect_to admin_teacher_record_passed_outcome_path(@teacher)
            else
              render :new
            end
          end

        else
          redirect_to admin_teacher_path(@teacher)
        end
      end

      private

      def record_passed_induction!
        ::AppropriateBodies::RecordPass.new(
          appropriate_body:,
          pending_induction_submission: @pending_induction_submission,
          author: current_user
        ).pass!
      end
    end
  end
end
