module Admin
  module Teachers
    class ReopenInductionController < AdminController
      def update
        @teacher = Teacher.find(params[:teacher_id])

        if last_induction_period.blank? || last_induction_period.ongoing?
          redirect_to admin_teacher_path(@teacher), notice: "No completed induction period found"
        end

        Admin::ReopenInductionPeriod.new(author: current_user, induction_period: last_induction_period).reopen_induction_period!

        redirect_to admin_teacher_path(@teacher)
      end

    private

      def last_induction_period
        @last_induction_period ||= ::Teachers::InductionPeriod.new(@teacher).last_induction_period
      end
    end
  end
end
