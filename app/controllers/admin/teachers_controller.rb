module Admin
  class TeachersController < AdminController
    layout "full"

    def index
      teacher_search = ::Admin::Teachers::Search.new(
        query_string: params[:q],
        role: params[:role],
        contract_period: params[:contract_period]
      )
      rows = ::Admin::Teachers::Rows.new(
        role: params[:role],
        contract_period: params[:contract_period]
      )

      @pagy, teachers = pagy(teacher_search.teacher_scope)
      @teacher_rows = rows.rows(teachers)
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
        "Teachers" => admin_teachers_path(helpers.admin_teacher_index_params),
        @teacher.full_name => nil
      }
    end
  end
end
