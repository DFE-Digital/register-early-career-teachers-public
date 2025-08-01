module Admin
  class SchoolsController < AdminController
    layout "full"

    before_action :config_search

    def index
      @breadcrumbs = {
        "Organisations" => admin_organisations_path,
        "Schools" => nil,
      }
      @pagy, @schools = pagy(Schools::Search.new(@q).call)
    end

    def show
      @school = School.includes(:gias_school).find_by(urn: school_params[:urn])
    end

  private

    def schools_params
      params.permit(:page, :q, :urn)
    end

    def school_params
      params.permit(:page, :q, :urn)
    end

    def config_search
      @q = schools_params[:q]
      @page = schools_params[:page] || 1
    end
  end
end
