module Admin
  module Teachers
    class TrainingsController < AdminController
      layout "full"

      def show
        @teacher = TeacherPresenter.new(Teacher.find(params[:teacher_id]))
        @navigation_items = helpers.admin_teacher_navigation_items(@teacher, :training)
        @breadcrumbs = teacher_breadcrumbs
        @ect_at_school_periods = @teacher.ect_at_school_periods
        @ect_training_periods = @teacher.ect_training_periods.includes(ect_at_school_period: :teacher).latest_first
        @period_ids_to_show_api_row = @ect_training_periods.group_by(&:lead_provider_delivery_partnership).values.map { it.first.id }
        @mentor_training_periods = @teacher.mentor_training_periods.includes(mentor_at_school_period: :teacher).latest_first
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
