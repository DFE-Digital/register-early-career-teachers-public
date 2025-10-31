module AppropriateBodies
  module Teachers
    class RecordPassedInductionController < CloseInductionController
      def new
        @record_pass = record_pass

        super
      end

      def create
        if @teacher.ongoing_induction_period.present?
          @record_pass = record_pass

          if @record_pass.call(induction_params)
            redirect_to ab_teacher_record_passed_outcome_path(@teacher)
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

      def record_pass
        RecordPass.new(
          teacher: @teacher,
          appropriate_body: @appropriate_body,
          author: current_user
        )
      end

      def induction_params
        params.expect(RecordPass.induction_params)
      end
    end
  end
end
