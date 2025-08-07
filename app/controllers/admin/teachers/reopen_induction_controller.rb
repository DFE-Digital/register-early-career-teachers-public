module Admin
  module Teachers
    class ReopenInductionController < AdminController
      def update
        @teacher = Teacher
          .includes(:last_induction_period)
          .find(params[:teacher_id])

        last_induction_period = @teacher.last_induction_period

        if last_induction_period.blank? ||
            last_induction_period.ongoing? ||
            last_induction_period.outcome.blank?
          return redirect_to admin_teacher_path(@teacher), notice: "No completed induction period found"
        end

        Admin::ReopenInductionPeriod.new(author: current_user, induction_period: last_induction_period).reopen_induction_period!

        redirect_to admin_teacher_path(@teacher)
      end
    end
  end
end
