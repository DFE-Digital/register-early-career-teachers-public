module AppropriateBodies
  module Teachers
    class ReleaseECTController < AppropriateBodiesController
      def new
        @teacher = find_current_teacher
        @pending_induction_submission = PendingInductionSubmission.new
      rescue ActiveRecord::RecordNotFound
        redirect_to ab_teacher_path(params[:teacher_id]), notice: "No active induction period found"
      end

      def create
        @teacher = find_current_teacher

        if current_teacher_ongoing_induction_period.present?

          @pending_induction_submission = PendingInductionSubmissions::Build.closing_induction_period(
            current_teacher_ongoing_induction_period,
            **pending_induction_submission_params,
            **pending_induction_submission_attributes
          ).pending_induction_submission

          release_ect = AppropriateBodies::ReleaseECT.new(
            appropriate_body: @appropriate_body,
            pending_induction_submission: @pending_induction_submission,
            author: current_user
          )

          PendingInductionSubmission.transaction do
            if @pending_induction_submission.save(context: :release_ect) && release_ect.release!
              redirect_to(ab_teacher_release_ect_path(@teacher))
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
        params.require(:pending_induction_submission).permit(:finished_on, :number_of_terms)
      end

      def pending_induction_submission_attributes
        { appropriate_body_id: @appropriate_body.id, trn: @teacher.trn }
      end

      def find_current_teacher
        AppropriateBodies::ECTs.new(@appropriate_body).current.find_by!(id: params[:teacher_id])
      end

      def find_former_teacher
        AppropriateBodies::ECTs.new(@appropriate_body).former.find_by!(id: params[:teacher_id])
      end

      def current_teacher_ongoing_induction_period
        @current_teacher_ongoing_induction_period ||= ::Teachers::InductionPeriod.new(@teacher).ongoing_induction_period
      end
    end
  end
end
