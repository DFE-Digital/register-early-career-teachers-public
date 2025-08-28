module Admin
  class SchoolsController < AdminController
    include Pagy::Backend

    layout "full"

    def index
      schools = params[:q].present? ? School.search(params[:q]) : School.includes(:gias_school)
      @pagy, @schools = pagy(schools)
    end

    def show
      redirect_to admin_school_overview_path(params[:urn])
    end
  end
end
