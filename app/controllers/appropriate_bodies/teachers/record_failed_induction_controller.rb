module AppropriateBodies
  module Teachers
    class RecordFailedInductionController < CloseInductionController
      before_action :record_fail, except: [:show]

      def confirm
      end

      def confirmed
        if confirmation_sent?
          redirect_to new_ab_teacher_record_failed_outcome_path(@teacher)
        else
          record_fail.errors.add(:confirmed, "Confirm if you have told them about their failed induction")
          render :confirm, status: :unprocessable_content
        end
      end

      def new
      end

      def show
      end

      def create
        if @teacher.ongoing_induction_period.present?
          if record_fail.call(induction_params)
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
        @record_fail = RecordFail.new(
          teacher: @teacher,
          appropriate_body_period: @appropriate_body,
          author: current_user
        )
      end

      def induction_params
        params.expect(RecordFail.induction_params)
      end

      def confirmation_sent?
        params.dig(:appropriate_bodies_record_fail, :confirmed)&.pop.present?
      end
    end
  end
end
