module AppropriateBodies
  module ClaimAnECT
    class FindECTController < AppropriateBodiesController
      def new
        @pending_induction_submission = PendingInductionSubmission.new
      end

      def not_found
      end

      def create
        @pending_induction_submission = find_ect.pending_induction_submission

        if find_ect.import_from_trs!
          redirect_to edit_ab_claim_an_ect_check_path(@pending_induction_submission)
        else
          render(:new)
        end

        # FIXME: I'm not especially fond of saving these throwaway pending induction
        #        submissions, can we not make the error pages generic and flash the
        #        details through instead?
      rescue TRS::Errors::QTSNotAwarded
        @pending_induction_submission.save!
        redirect_to ab_claim_an_ect_errors_no_qts_path(@pending_induction_submission)
      rescue TRS::Errors::ProhibitedFromTeaching
        @pending_induction_submission.save!
        redirect_to ab_claim_an_ect_errors_prohibited_path(@pending_induction_submission)
      rescue TRS::Errors::InductionAlreadyCompleted
        @pending_induction_submission.save!
        redirect_to edit_ab_claim_an_ect_check_path(@pending_induction_submission)
      rescue TRS::Errors::TeacherNotFound, TRS::Errors::TeacherDeactivated
        @pending_induction_submission.errors.add(:base, "No teacher with this TRN and date of birth was found")

        render(:new)
      rescue AppropriateBodies::Errors::TeacherHasActiveInductionPeriodWithCurrentAB => e
        teacher_id = Teacher.find_by!(trn: @pending_induction_submission.trn).id

        redirect_to(ab_teacher_path(teacher_id), notice: e.message)
      end

    private

      def pending_induction_submission_params
        params.expect(pending_induction_submission: %i[trn date_of_birth])
      end

      def pending_induction_submission_attributes
        { appropriate_body_id: @appropriate_body.id }
      end

      def find_ect
        @find_ect ||=
          AppropriateBodies::ClaimAnECT::FindECT.new(
            appropriate_body: @appropriate_body,
            pending_induction_submission: PendingInductionSubmission.new(
              **pending_induction_submission_params,
              **pending_induction_submission_attributes
            )
          )
      end
    end
  end
end
