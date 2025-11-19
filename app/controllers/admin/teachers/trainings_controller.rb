module Admin
  module Teachers
    class TrainingsController < AdminController
      layout "full"

      def show
        @teacher = TeacherPresenter.new(Teacher.find(params[:teacher_id]))
        @breadcrumbs = teacher_breadcrumbs
      end

    private

      def teacher_breadcrumbs
        {
          "Teachers" => admin_teachers_path(page: params[:page], q: params[:q]),
          # @teacher.full_name => admin_teacher_path(@teacher, page: params[:page], q: params[:q]), #todo: uncomment once https://github.com/DFE-Digital/register-early-career-teachers-public/pull/1741 is merged
          "Training" => nil
        }
      end
    end
  end
end
