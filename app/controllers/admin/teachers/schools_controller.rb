module Admin
  module Teachers
    class SchoolsController < AdminController
      layout "full"

      def show
        @teacher = TeacherPresenter.new(Teacher.find_by(id: params[:teacher_id]))
        @navigation_items = helpers.admin_teacher_navigation_items(@teacher, :school)
        @breadcrumbs = teacher_breadcrumbs
      end

    private

      def teacher_breadcrumbs
        {
          "Teachers" => admin_teachers_path(page: params[:page], q: params[:q]),
          @teacher.full_name => admin_teacher_path(@teacher, page: params[:page], q: params[:q]),
          "School" => nil
        }
      end
    end
  end
end
