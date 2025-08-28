module Admin
  class SchoolsController < AdminController
    include Pagy::Backend

    layout "full"

    def index
      schools = params[:q].present? ? School.search(params[:q]) : School.includes(:gias_school)
      @pagy, @schools = pagy(schools)
    end

    def show
      @school = School.includes(:gias_school).find_by!(urn: params[:urn])
      @breadcrumbs = {
        "Schools" => admin_schools_path(page: params[:page], q: params[:q]),
        @school.name => nil
      }
    end
  end
end
