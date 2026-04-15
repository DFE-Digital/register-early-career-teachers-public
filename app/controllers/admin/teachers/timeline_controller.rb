module Admin
  module Teachers
    class TimelineController < AdminController
      layout "full"

      def show
        teacher = Teacher.find_by(id: params[:teacher_id])
        @teacher = TeacherPresenter.new(teacher)
        @events = Events::List.new.for_teacher(@teacher)
        @navigation_items = helpers.admin_teacher_navigation_items(@teacher, :timeline)
        @breadcrumbs = teacher_breadcrumbs
      end

    private

      def teacher_breadcrumbs
        {
          "Teachers" => admin_teachers_path(page: params[:page], q: params[:q]),
          @teacher.full_name => admin_teacher_path(@teacher, page: params[:page], q: params[:q]),
          "Timeline" => nil
        }
      end
    end
  end
end
