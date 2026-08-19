module Admin
  module Schools
    class TeachersController < AdminController
      layout "full"

      def show
        @school = School.includes(:gias_school).find_by!(urn: params[:school_urn])
        teacher_search = TeacherSearch.new(
          school: @school,
          query_string: params[:q],
          role: params[:role],
          contract_period: params[:contract_period]
        )
        @teacher_rows = teacher_search.rows
        @has_current_teachers = teacher_search.has_current_teachers?
        @breadcrumbs = {
          "Schools" => admin_schools_path(page: params[:page], q: params[:q]),
          @school.name => nil
        }
        @navigation_items = helpers.admin_school_navigation_items(params[:school_urn], request.path)
      end
    end
  end
end
