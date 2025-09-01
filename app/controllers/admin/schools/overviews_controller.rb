module Admin
  module Schools
    class OverviewsController < AdminController
      layout "full"

      def show
        @school = School.includes(:gias_school).find_by!(urn: params[:school_urn])
        @breadcrumbs = {
          "Schools" => admin_schools_path(page: params[:page], q: params[:q]),
          @school.name => nil
        }
        @navigation_items = helpers.admin_school_navigation_items(params[:school_urn], request.fullpath)
      end
    end
  end
end
