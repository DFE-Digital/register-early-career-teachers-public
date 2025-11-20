module Admin
  module Teachers
    class TrainingsController < AdminController
      layout "full"

      def show
        @teacher = TeacherPresenter.new(Teacher.find(params[:teacher_id]))
        @breadcrumbs = teacher_breadcrumbs
        @ect_training_periods = @teacher.ect_training_periods.order(started_on: :desc)
        @mentor_training_periods = @teacher.mentor_training_periods.order(started_on: :desc)
      end

    private

      def teacher_breadcrumbs
        {
          "Teachers" => admin_teachers_path(page: params[:page], q: params[:q]),
          @teacher.full_name => admin_teacher_path(@teacher, page: params[:page], q: params[:q]),
          "Training" => nil
        }
      end
    end
  end
end
