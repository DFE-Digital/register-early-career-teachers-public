module Admin
  module Teachers
    class RecordFailedInductionController < CloseInductionController
      def create
        if @teacher.ongoing_induction_period.present?
          @pending_induction_submission = build_closing_induction_period(outcome: 'fail')

          if @pending_induction_submission.save(context: :record_outcome) && record_fail.fail!
            redirect_to admin_teacher_record_failed_outcome_path(@teacher)
          else
            render :new, status: :unprocessable_content
          end

        else
          redirect_to admin_teacher_path(@teacher)
        end
      rescue ActiveModel::ValidationError
        record_fail.errors.each do |error|
          @pending_induction_submission.errors.add(error.attribute, error.message)
        end

        render :new, status: :unprocessable_content
      end

    private

      def record_fail
        @record_fail ||= RecordFail.new(
          appropriate_body:,
          pending_induction_submission: @pending_induction_submission,
          **auditable_params
        )
      end
    end
  end
end
