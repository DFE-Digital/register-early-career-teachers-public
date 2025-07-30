module Admin
  class AppropriateBodiesController < AdminController
    include Pagy::Backend

    layout 'full', only: 'index'

    def index
      @breadcrumbs = {
        "Organisations" => admin_organisations_path,
        "Appropriate bodies" => nil,
      }
      @pagy, @appropriate_bodies = pagy(
        ::AppropriateBodies::Search.new(params[:q]).search,
        limit: 30
      )
    end

    def show
      @appropriate_body = AppropriateBody.find(params[:id])
      @current_ect_count = ::Teachers::Search.new(appropriate_bodies: @appropriate_body).search.count
    end
  end
end
