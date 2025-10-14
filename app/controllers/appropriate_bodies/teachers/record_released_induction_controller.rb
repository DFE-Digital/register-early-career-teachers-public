module AppropriateBodies
  module Teachers
    class RecordReleasedInductionController < CloseInductionController
      def create
        if @teacher.ongoing_induction_period.present?
          @pending_induction_submission = build_closing_induction_period(outcome: nil)

          PendingInductionSubmission.transaction do
            if @pending_induction_submission.save(context: :release_ect) && record_released_induction!
              redirect_to ab_teacher_release_ect_path(@teacher)
            else
              render :new
            end
          end

        else
          redirect_to ab_teacher_path(@teacher)
        end
      end

    private

      def pending_induction_submission_params
        params.expect(pending_induction_submission: %i[finished_on number_of_terms])
      end

      def find_current_teacher
        @teacher = ects.current.find_by!(id: params[:teacher_id])
      end

      def find_former_teacher
        @teacher = ects.former.find_by!(id: params[:teacher_id])
      end

      def record_released_induction!
        RecordRelease.new(
          appropriate_body: @appropriate_body,
          pending_induction_submission: @pending_induction_submission,
          author: current_user
        ).release!
      end
    end
  end
end
