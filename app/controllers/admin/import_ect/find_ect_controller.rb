module Admin
  module ImportECT
    class FindECTController < AdminController
      layout "full"

      def new
        @pending_induction_submission = PendingInductionSubmission.new
      end

      def create
        @pending_induction_submission = find_ect.pending_induction_submission

        if find_ect.import_from_trs!
          redirect_to edit_admin_import_ect_check_path(@pending_induction_submission)
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
        redirect_to edit_admin_import_ect_check_path(@pending_induction_submission)

      # Already registered
      rescue Admin::Errors::TeacherAlreadyExists
        existing_teacher = Teacher.find_by(trn: @pending_induction_submission.trn)
        redirect_to admin_teacher_induction_path(existing_teacher), notice: "Teacher #{existing_teacher.trn} already exists in the system"
      end

    private

      def pending_induction_submission_params
        params.expect(pending_induction_submission: %i[trn date_of_birth])
      end

      def find_ect
        @find_ect ||=
          Admin::ImportECT::FindECT.new(
            pending_induction_submission: PendingInductionSubmission.new(
              **pending_induction_submission_params
            )
          )
      end
    end
  end
end
