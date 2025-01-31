module AppropriateBodies
  module Teachers
    class ReleaseECTController < AppropriateBodiesController
      def new
        @teacher = find_teacher

        @pending_induction_submission = PendingInductionSubmission.new
      end

      def create
        @teacher = find_teacher
        @pending_induction_submission = PendingInductionSubmissions::Build.closing_induction_period(
          ::Teachers::InductionPeriod.new(@teacher).active_induction_period,
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
            redirect_to(
              ab_teacher_release_ect_path(@teacher),
              flash: { teacher_name: ::Teachers::Name.new(@teacher).full_name }
            )
          else
            render :new
          end
        end
      rescue ::AppropriateBodies::Errors::ECTHasNoOngoingInductionPeriods => e
        @pending_induction_submission.errors.add(:base, message: e.message)
        render :new
      end

      def show
        @teacher_name = flash['teacher_name']
      end

    private

      def pending_induction_submission_params
        params.require(:pending_induction_submission).permit(:finished_on, :number_of_terms)
      end

      def pending_induction_submission_attributes
        { appropriate_body_id: @appropriate_body.id, trn: @teacher.trn }
      end

      def find_teacher
        AppropriateBodies::CurrentTeachers.new(@appropriate_body).current.find_by!(id: params[:teacher_id])
      end
    end
  end
end
