module AppropriateBodies
  module Teachers
    class RecordPassedInductionController < CloseInductionController
      def create
        if @teacher.ongoing_induction_period.present?
          @pending_induction_submission = build_closing_induction_period(outcome: 'pass')

          if @pending_induction_submission.save(context: :record_outcome) && record_pass.pass!
            redirect_to ab_teacher_record_passed_outcome_path(@teacher)
          else
            render :new, status: :unprocessable_content
          end

        else
          redirect_to ab_teacher_path(@teacher)
        end
      end

    private

      def record_pass
        @record_pass ||= RecordPass.new(
          appropriate_body: @appropriate_body,
          pending_induction_submission: @pending_induction_submission,
          author: current_user
        )
      end
    end
  end
end
