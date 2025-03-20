module Admin
  module Teachers
    class RecordFailedOutcomeController < AdminController
      def new
        @teacher = Teacher.find(params[:teacher_id])
        @pending_induction_submission = PendingInductionSubmission.new

        if current_teacher_ongoing_induction_period.blank?
          redirect_to admin_teacher_path(@teacher), notice: "No active induction period found"
        end
      end

      def create
        @teacher = Teacher.find(params[:teacher_id])

        if current_teacher_ongoing_induction_period.present?
          @pending_induction_submission = PendingInductionSubmissions::Build.closing_induction_period(
            current_teacher_ongoing_induction_period,
            **pending_induction_submission_params,
            **pending_induction_submission_attributes
          ).pending_induction_submission

          record_outcome = ::AppropriateBodies::RecordOutcome.new(
            appropriate_body: current_teacher_ongoing_induction_period.appropriate_body,
            pending_induction_submission: @pending_induction_submission,
            teacher: @teacher,
            author: current_user
          )

          PendingInductionSubmission.transaction do
            if @pending_induction_submission.save(context: :record_outcome) && record_outcome.fail!
              redirect_to(admin_teacher_record_failed_outcome_path(@teacher))
            else
              render :new
            end
          end

        else
          redirect_to admin_teacher_path(@teacher)
        end
      end

      def show
        @teacher = Teacher.find(params[:teacher_id])
      end

    private

      def pending_induction_submission_params
        params.require(:pending_induction_submission).permit(:finished_on, :number_of_terms, :outcome)
      end

      def pending_induction_submission_attributes
        { appropriate_body_id: current_teacher_ongoing_induction_period.appropriate_body.id, trn: @teacher.trn, outcome: "fail" }
      end

      def current_teacher_ongoing_induction_period
        @current_teacher_ongoing_induction_period ||= ::Teachers::InductionPeriod.new(@teacher).ongoing_induction_period
      end
    end
  end
end
