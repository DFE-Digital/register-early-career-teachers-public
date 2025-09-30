module Admin
  module Teachers
    class RecordOutcomeController < AdminController
      before_action :find_teacher

      def new
        @pending_induction_submission = PendingInductionSubmission.new

        if @teacher.ongoing_induction_period.blank?
          redirect_to admin_teacher_path(@teacher), notice: "No active induction period found"
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
          appropriate_body_id: appropriate_body.id,
          trn: @teacher.trn,
        }
      end

      def find_teacher
        @teacher = Teacher.find(params[:teacher_id])
      end

      def appropriate_body
        @teacher.ongoing_induction_period.appropriate_body
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
