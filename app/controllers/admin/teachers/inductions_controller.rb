module Admin
  module Teachers
    class InductionsController < AdminController
      layout "full"

      def show
        @page = params[:page] || 1
        teacher = Teacher.find_by(id: params[:teacher_id])
        @teacher = TeacherPresenter.new(teacher)
        @events = teacher.events.latest_first
        @navigation_items = helpers.admin_teacher_navigation_items(@teacher, :induction)
        @breadcrumbs = teacher_breadcrumbs
      end

    private

      def teacher_breadcrumbs
        {
          "Teachers" => admin_teachers_path(page: params[:page], q: params[:q]),
          @teacher.full_name => admin_teacher_path(@teacher, page: params[:page], q: params[:q]),
          "Induction" => nil
        }
      end
    end
  end
end
