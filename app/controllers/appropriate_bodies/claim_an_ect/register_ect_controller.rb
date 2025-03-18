module AppropriateBodies
  module ClaimAnECT
    class RegisterECTController < AppropriateBodiesController
      def edit
        @pending_induction_submission = find_pending_induction_submission
      end

      # OPTIMIZE: Pre-model validations are required to guard against
      # ActiveRecord::MultiparameterAssignmentErrors
      # when dates are non-existent or incorrect dates when one day from the month's end
      # for example 31st Sept becomes 1st Oct
      # or when negative numbers are passed in by mistake
      def update
        if hash_date.valid? && register_ect.register(update_params)
          redirect_to(ab_claim_an_ect_register_path(register_ect.pending_induction_submission))
        else
          @pending_induction_submission = register_ect.pending_induction_submission
          @pending_induction_submission.errors.add(:started_on, hash_date.error_message) unless hash_date.valid?

          render(:edit)
        end
      end

      def show
        @pending_induction_submission = find_pending_induction_submission
      end

    private

      def update_params
        params.require(:pending_induction_submission).permit(:started_on, :induction_programme, :trs_induction_status)
      end

      def find_pending_induction_submission
        PendingInductionSubmissions::Search.new(appropriate_body: @appropriate_body).pending_induction_submissions.find(params[:id])
      end

      def register_ect
        @register_ect ||= AppropriateBodies::ClaimAnECT::RegisterECT.new(
          appropriate_body: @appropriate_body,
          pending_induction_submission: find_pending_induction_submission,
          author: current_user
        )
      end

      def hash_date
        @hash_date ||= Schools::Validation::HashDate.new({
          1 => update_params['started_on(1i)'], # Year
          2 => update_params['started_on(2i)'], # Month
          3 => update_params['started_on(3i)']  # Day
        })
      end
    end
  end
end
