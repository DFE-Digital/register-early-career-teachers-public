module Admin
  module Teachers
    class InductionsController < AdminController
      layout "full"

      def show
        @page = params[:page] || 1
        teacher = Teacher.find_by(id: params[:teacher_id])
        @teacher = TeacherPresenter.new(teacher)
        @events = teacher.events.latest_first
      end
    end
  end
end
