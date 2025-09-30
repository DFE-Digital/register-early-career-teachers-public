module AppropriateBodies
  module ClaimAnECT
    class FindECTController < AppropriateBodiesController
      layout 'full'

      def new
        @pending_induction_submission = PendingInductionSubmission.new
      end

      def create
        @pending_induction_submission = find_ect.pending_induction_submission

        if find_ect.import_from_trs!
          redirect_to edit_ab_claim_an_ect_check_path(@pending_induction_submission)
        else
          render :new
        end

      # Not in TRS
      rescue TRS::Errors::TeacherNotFound, TRS::Errors::TeacherDeactivated
        @pending_induction_submission.errors.add(:base, "No teacher with this TRN and date of birth was found")
        render :new

      # Not claimable
      rescue TRS::Errors::InductionAlreadyCompleted, TRS::Errors::QTSNotAwarded, TRS::Errors::ProhibitedFromTeaching
        @pending_induction_submission.save!
        redirect_to edit_ab_claim_an_ect_check_path(@pending_induction_submission)

      # Already claimed by current AB
      rescue FindECT::TeacherHasOngoingInductionPeriodWithCurrentAB
        teacher = Teacher.find_by(trn: @pending_induction_submission.trn)
        full_name = ::Teachers::Name.new(teacher).full_name
        redirect_to ab_teacher_path(teacher), notice: "Teacher #{full_name} already has an ongoing induction period with this appropriate body"
      end

    private

      def pending_induction_submission_params
        params.expect(pending_induction_submission: %i[trn date_of_birth])
      end

      def pending_induction_submission_attributes
        { appropriate_body_id: @appropriate_body.id }
      end

      def find_ect
        @find_ect ||= FindECT.new(
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
