module Admin
  class TeachersController < AdminController
    layout "full"

    def index
      teacher_search = ::Admin::Teachers::Search.new(
        query_string: params[:q]
      )
      row_query = ::Admin::Teachers::RowQuery.new(
        matching_teacher_scope: teacher_search.search,
        role: params[:role],
        contract_period: params[:contract_period]
      )

      @pagy, paginated_teacher_rows = pagy(row_query.relation, count: row_query.count)
      @teacher_rows = row_query.rows(paginated_teacher_rows)
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
