module AppropriateBodies
  module Teachers
    class RecordOutcomeController < AppropriateBodiesController
      def new
        @teacher = find_current_teacher
        @pending_induction_submission = PendingInductionSubmission.new

        if @teacher.ongoing_induction_period.blank?
          redirect_to ab_teacher_path(@teacher), notice: "No active induction period found"
        end
      end

      def show
        @teacher = find_former_teacher
      end

    private

      def pending_induction_submission_params
        params.expect(pending_induction_submission: %i[finished_on number_of_terms outcome])
      end

      def pending_induction_submission_attributes
        {
          appropriate_body_id: @appropriate_body.id,
          trn: @teacher.trn,
        }
      end

      def find_former_teacher
        AppropriateBodies::ECTs.new(@appropriate_body).current_or_completed_while_at_appropriate_body.find_by!(id: params[:teacher_id])
      end

      def find_current_teacher
        AppropriateBodies::ECTs.new(@appropriate_body).current_or_completed_while_at_appropriate_body.find_by!(id: params[:teacher_id])
      end

      def build_closing_induction_period(outcome: nil)
        PendingInductionSubmissions::Build.closing_induction_period(
          @teacher.ongoing_induction_period,
          **pending_induction_submission_params,
          **pending_induction_submission_attributes,
          outcome:
        ).pending_induction_submission
      end
    end
  end
end
