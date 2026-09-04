module Admin
  class AppropriateBodiesController < AdminController
    include Pagy::Backend

    layout "full"

    def index
      @breadcrumbs = {
        "Organisations" => admin_organisations_path,
        "Appropriate bodies" => nil,
      }
      @include_de_designated = params[:include_de_designated] == "1"
      @pagy, @appropriate_bodies = pagy(appropriate_bodies)
    end

    def show
      @appropriate_body = AppropriateBodyPeriod.find(params[:id])
    end

  private

    def appropriate_bodies
      scope = ::AppropriateBodies::Search.new(params[:q]).search

      @include_de_designated ? scope : scope.active
    end
  end
end
