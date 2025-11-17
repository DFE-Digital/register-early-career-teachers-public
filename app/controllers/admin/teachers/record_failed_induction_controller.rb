module Admin
  module Teachers
    class RecordFailedInductionController < CloseInductionController
      def new
        @record_fail = RecordFail.new(
          teacher: @teacher,
          appropriate_body:,
          author: current_user
        )

        super
      end

      def create
        if @teacher.ongoing_induction_period.present?
          @record_fail = RecordFail.new(
            teacher: @teacher,
            appropriate_body:,
            author: current_user,
            **auditable_params
          )

          if @record_fail.call(induction_params)
            redirect_to admin_teacher_record_failed_outcome_path(@teacher)
          else
            render :new, status: :unprocessable_content
          end

        else
          redirect_to admin_teacher_induction_path(@teacher)
        end
      rescue ActiveRecord::RecordInvalid,
             ActiveModel::ValidationError
        render :new, status: :unprocessable_content
      end

    private

      def auditable_params
        params.expect(RecordFail.auditable_params)
      end

      def induction_params
        params.expect(RecordFail.induction_params)
      end
    end
  end
end
