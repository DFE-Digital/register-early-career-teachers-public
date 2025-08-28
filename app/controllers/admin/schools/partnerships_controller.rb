module Admin
  module Schools
    class PartnershipsController < AdminController
      layout "full"

      before_action :setup_school_page
      before_action :setup_navigation_items

      def show
      end

    private

      def setup_school_page
        @school = School.includes(:gias_school).find_by!(urn: params[:school_urn])
        @breadcrumbs = {
          "Schools" => admin_schools_path(page: params[:page], q: params[:q]),
          @school.name => nil
        }
      end

      def setup_navigation_items
        @navigation_items = helpers.admin_school_navigation_items(params[:school_urn], request.fullpath)
      end
    end
  end
end
