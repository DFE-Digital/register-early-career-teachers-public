module Admin
  class AppropriateBodiesController < AdminController
    include Pagy::Backend

    layout 'full'

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
    end
  end
end
