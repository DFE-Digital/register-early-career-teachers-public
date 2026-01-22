module Admin
  module Teachers
    class TrainingsController < AdminController
      layout "full"

      def show
        @teacher = TeacherPresenter.new(Teacher.find(params[:teacher_id]))
        @navigation_items = helpers.admin_teacher_navigation_items(@teacher, :training)
        @breadcrumbs = teacher_breadcrumbs
        @ect_at_school_periods = @teacher.ect_at_school_periods
        @ect_training_periods = @teacher.ect_training_periods.includes(ect_at_school_period: :teacher).order(started_on: :desc).group_by(&:lead_provider_delivery_partnership)
        @mentor_training_periods = @teacher.mentor_training_periods.includes(mentor_at_school_period: :teacher).order(started_on: :desc)
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
