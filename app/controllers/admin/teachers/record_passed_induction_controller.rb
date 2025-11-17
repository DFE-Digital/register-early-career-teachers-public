module Admin
  module Teachers
    class RecordPassedInductionController < CloseInductionController
      def new
        @record_pass = RecordPass.new(
          teacher: @teacher,
          appropriate_body:,
          author: current_user
        )

        super
      end

      def create
        if @teacher.ongoing_induction_period.present?
          @record_pass = RecordPass.new(
            teacher: @teacher,
            appropriate_body:,
            author: current_user,
            **auditable_params
          )

          if @record_pass.call(induction_params)
            redirect_to admin_teacher_record_passed_outcome_path(@teacher)
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
        params.expect(RecordPass.auditable_params)
      end

      def induction_params
        params.expect(RecordPass.induction_params)
      end
    end
  end
end
