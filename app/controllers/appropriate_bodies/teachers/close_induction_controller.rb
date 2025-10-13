module AppropriateBodies
  module Teachers
    class CloseInductionController < AppropriateBodiesController
      before_action :find_former_teacher, only: [:show]
      before_action :find_current_teacher, except: [:show]

      def new
        @pending_induction_submission = PendingInductionSubmission.new

        if @teacher.ongoing_induction_period.blank?
          redirect_to ab_teacher_path(@teacher), notice: "No active induction period found"
        end
      end

      def show
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
        @teacher = ects.current_or_completed_while_at_appropriate_body.find_by!(id: params[:teacher_id])
      end

      def find_current_teacher
        @teacher = ects.current_or_completed_while_at_appropriate_body.find_by!(id: params[:teacher_id])
      end

      def build_closing_induction_period(outcome: nil)
        PendingInductionSubmissions::Build.closing_induction_period(
          @teacher.ongoing_induction_period,
          **pending_induction_submission_params,
          **pending_induction_submission_attributes,
          outcome:
        ).pending_induction_submission
      end

      def ects
        AppropriateBodies::ECTs.new(@appropriate_body)
      end
    end
  end
end
