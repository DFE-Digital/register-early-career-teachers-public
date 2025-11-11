module Admin
  class SchoolsController < AdminController
    include Pagy::Backend

    layout "full"

    def index
      schools = ::Schools::Search.new(params[:q]).search
      @pagy, @schools = pagy(schools)
    end

    def show
      redirect_to admin_school_overview_path(params[:urn])
    end
  end
end
