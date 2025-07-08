module Admin
  module ClaimAnECT
    class FindECTController < AdminController
      before_action :set_appropriate_body

      def new
        @pending_induction_submission = PendingInductionSubmission.new(appropriate_body: @appropriate_body)
      end

      def not_found
      end

      def create
        find_ect = Admin::ClaimAnECT::FindECT
        .new(
          pending_induction_submission: PendingInductionSubmission.new(
            **pending_induction_submission_params,
            **pending_induction_submission_attributes.merge(appropriate_body: @appropriate_body)
          )
        )
        @pending_induction_submission = find_ect.pending_induction_submission

        if find_ect.import_from_trs!
          redirect_to(edit_admin_appropriate_body_claim_an_ect_check_path(@appropriate_body, find_ect.pending_induction_submission))
        else
          render(:new)
        end
      rescue TRS::Errors::QTSNotAwarded
        @pending_induction_submission.save!
        redirect_to admin_appropriate_body_claim_an_ect_errors_no_qts_path(@appropriate_body, @pending_induction_submission)
      rescue TRS::Errors::ProhibitedFromTeaching
        @pending_induction_submission.save!
        redirect_to admin_appropriate_body_claim_an_ect_errors_prohibited_path(@appropriate_body, @pending_induction_submission)
      rescue TRS::Errors::TeacherNotFound, TRS::Errors::TeacherDeactivated
        @pending_induction_submission.errors.add(:base, "No teacher with this TRN and date of birth was found")

        render(:new)
      rescue Admin::Errors::TeacherAlreadyExists => e
        teacher_id = Teacher.find_by!(trn: find_ect.pending_induction_submission.trn).id

        redirect_to(admin_teacher_path(teacher_id), notice: e.message)
      end

    private

      def pending_induction_submission_params
        params.require(:pending_induction_submission).permit(:trn, :date_of_birth)
      end

      def pending_induction_submission_attributes
        {}
      end

      def set_appropriate_body
        @appropriate_body = AppropriateBody.find(params[:appropriate_body_id])
      end
    end
  end
end
