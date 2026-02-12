module Admin
  module Teachers
    class CloseInductionController < AdminController
      before_action :find_teacher

      def new
        if @teacher.ongoing_induction_period.blank?
          redirect_to admin_teacher_induction_path(@teacher), notice: "No active induction period found"
        end
      end

      def show
      end

    private

      def find_teacher
        @teacher = Teacher.find(params[:teacher_id])
      end

      def appropriate_body_period
        @teacher.ongoing_induction_period.appropriate_body_period
      end
    end
  end
end
