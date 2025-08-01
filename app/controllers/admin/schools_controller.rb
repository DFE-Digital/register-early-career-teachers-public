module Admin
  class SchoolsController < AdminController
    include Pagy::Backend

    layout "full"

    def index
      @pagy, @schools = pagy(Schools::Search.new(params[:q]).call)
    end

    def show
      @school = School.includes(:gias_school).find_by!(urn: params[:urn])
    end
  end
end
