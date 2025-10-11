module AppropriateBodies
  module Teachers
    # TODO: rename ReleaseECTController to RecordReleaseController
    # TODO: inherit ReleaseECTController from RecordOutcomeController
    class ReleaseECTController < AppropriateBodiesController
      def new
        @teacher = find_current_teacher
        @pending_induction_submission = PendingInductionSubmission.new
      rescue ActiveRecord::RecordNotFound
        redirect_to ab_teacher_path(params[:teacher_id]), notice: "No active induction period found"
      end

      def create
        @teacher = find_current_teacher

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

      def show
        @teacher = find_former_teacher
      end

    private

      def pending_induction_submission_params
        params.expect(pending_induction_submission: %i[finished_on number_of_terms])
      end

      def pending_induction_submission_attributes
        {
          appropriate_body_id: @appropriate_body.id,
          trn: @teacher.trn
        }
      end

      def find_current_teacher
        AppropriateBodies::ECTs.new(@appropriate_body).current.find_by!(id: params[:teacher_id])
      end

      def find_former_teacher
        AppropriateBodies::ECTs.new(@appropriate_body).former.find_by!(id: params[:teacher_id])
      end

      def record_released_induction!
        AppropriateBodies::RecordRelease.new(
          appropriate_body: @appropriate_body,
          pending_induction_submission: @pending_induction_submission,
          author: current_user
        ).release!
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
