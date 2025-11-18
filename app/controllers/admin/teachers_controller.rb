module Admin
  class TeachersController < AdminController
    layout "full"

    def index
      @appropriate_bodies = AppropriateBody.order(:name)
      @pagy, @teachers = pagy(
        ::Teachers::Search.new(
          query_string: params[:q]
        )
        .search
        .includes(
          :induction_periods,
          :current_appropriate_body
        )
      )
    end

    def show
      @navigation_items = helpers.admin_teacher_navigation_items(teacher, :overview)
    end

  private

    def teacher
      @teacher = TeacherPresenter.new(Teacher.find(params[:id]))
    end
  end
end
