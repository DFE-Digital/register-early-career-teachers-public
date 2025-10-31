module AppropriateBodies
  module Teachers
    class RecordFailedInductionController < CloseInductionController
      def new
        @record_fail = record_fail

        super
      end

      def create
        if @teacher.ongoing_induction_period.present?
          @record_fail = record_fail

          if @record_fail.call(induction_params)
            redirect_to ab_teacher_record_failed_outcome_path(@teacher)
          else
            render :new, status: :unprocessable_content
          end

        else
          redirect_to ab_teacher_path(@teacher)
        end
      rescue ActiveRecord::RecordInvalid,
             ActiveModel::ValidationError
        render :new, status: :unprocessable_content
      end

    private

      def record_fail
        RecordFail.new(
          teacher: @teacher,
          appropriate_body: @appropriate_body,
          author: current_user
        )
      end

      def induction_params
        params.expect(RecordFail.induction_params)
      end
    end
  end
end
