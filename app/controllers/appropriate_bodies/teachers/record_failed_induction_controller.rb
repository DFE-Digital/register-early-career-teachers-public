module AppropriateBodies
  module Teachers
    class RecordFailedInductionController < CloseInductionController
      def create
        if @teacher.ongoing_induction_period.present?
          @pending_induction_submission = build_closing_induction_period(outcome: 'fail')

          PendingInductionSubmission.transaction do
            if @pending_induction_submission.save(context: :record_outcome) && record_failed_induction!
              redirect_to ab_teacher_record_failed_outcome_path(@teacher)
            else
              render :new
            end
          end

        else
          redirect_to ab_teacher_path(@teacher)
        end
      end

    private

      def record_failed_induction!
        RecordFail.new(
          appropriate_body: @appropriate_body,
          pending_induction_submission: @pending_induction_submission,
          author: current_user
        ).fail!
      end
    end
  end
end
