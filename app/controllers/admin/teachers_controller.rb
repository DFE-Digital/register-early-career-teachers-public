module Admin
  class TeachersController < AdminController
    layout "full"

    def index
      @appropriate_bodies = AppropriateBodyPeriod.order(:name)
      @pagy, @teachers = pagy(
        ::Teachers::Search.new(
          query_string: params[:q]
        )
        .search
        .includes(
          :induction_periods,
          :current_appropriate_body_period
        )
      )
    end

    def show
      @navigation_items = helpers.admin_teacher_navigation_items(teacher, :overview)
      @breadcrumbs = teacher_breadcrumbs
    end

  private

    def teacher
      @teacher = TeacherPresenter.new(Teacher.find(params[:id]))
    end

    def teacher_breadcrumbs
      {
        "Teachers" => admin_teachers_path(page: params[:page], q: params[:q]),
        @teacher.full_name => nil
      }
    end
  end
end
