module Admin
  class SchoolsController < AdminController
    include Pagy::Backend

    layout "full"

    before_action :setup_school_page, only: %i[overview teachers partnerships]
    before_action :setup_navigation_items, only: %i[overview teachers partnerships]

    def index
      schools = params[:q].present? ? School.search(params[:q]) : School.includes(:gias_school)
      @pagy, @schools = pagy(schools)
    end

    def show
      redirect_to overview_admin_school_path(params[:urn])
    end

    def overview
    end

    def teachers
    end

    def partnerships
    end

  private

    def setup_school_page
      @school = School.includes(:gias_school).find_by!(urn: params[:urn])
      @breadcrumbs = {
        "Schools" => admin_schools_path(page: params[:page], q: params[:q]),
        @school.name => nil
      }
    end

    def setup_navigation_items
      current_path = request.fullpath
      school_urn = params[:urn]

      @navigation_items = [
        {
          text: "Overview",
          href: overview_admin_school_path(school_urn),
          current: current_path == overview_admin_school_path(school_urn)
        },
        {
          text: "Teachers",
          href: teachers_admin_school_path(school_urn),
          current: current_path == teachers_admin_school_path(school_urn)
        },
        {
          text: "Partnerships",
          href: partnerships_admin_school_path(school_urn),
          current: current_path == partnerships_admin_school_path(school_urn)
        }
      ]
    end
  end
end
