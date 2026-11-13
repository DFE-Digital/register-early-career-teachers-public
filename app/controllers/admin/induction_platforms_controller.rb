module Admin
  class InductionPlatformsController < AdminController
    layout "full"

    def index
      @breadcrumbs = {
        "Organisations" => admin_organisations_path,
        "Induction platforms" => nil,
      }
      @induction_platforms = API::OAuth::Client.order(:name)
    end

    def show
      @induction_platform = API::OAuth::Client.find(params[:id])
      @breadcrumbs = {
        "Organisations" => admin_organisations_path,
        "Induction platforms" => admin_induction_platforms_path,
        @induction_platform.name => nil,
      }
      @authorizations = @induction_platform
        .authorizations
        .active
        .eager_load(:appropriate_body_period)
        .merge(AppropriateBodyPeriod.order(:name))
    end
  end
end
