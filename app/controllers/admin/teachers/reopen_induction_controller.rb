module Admin
  module Teachers
    class ReopenInductionController < AdminController
      before_action :set_teacher

      before_action -> do
        redirect_to admin_teacher_path(@teacher),
                    notice: "No completed induction period found"
      end, unless: :induction_complete_with_outcome?

      def update
        Admin::ReopenInductionPeriod.new(
          author: current_user,
          induction_period: @teacher.last_induction_period
        ).reopen_induction_period!

        redirect_to admin_teacher_path(@teacher),
                    alert: "Induction was successfully reopened"
      end

    private

      def set_teacher
        @teacher = Teacher
          .includes(:last_induction_period)
          .find(params[:teacher_id])
      end

      def induction_complete_with_outcome?
        @teacher.last_induction_period&.complete? &&
          @teacher.last_induction_period.outcome?
      end
    end
  end
end
