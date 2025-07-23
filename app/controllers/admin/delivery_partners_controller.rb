module Admin
  class DeliveryPartnersController < AdminController
    include Pagy::Backend

    layout 'full', only: 'index'

    def index
      @breadcrumbs = {
        "Organisations" => admin_organisations_path,
        "Delivery partners" => nil,
      }
      @pagy, @delivery_partners = pagy(
        ::DeliveryPartners::Search.new(params[:q]).search,
        limit: 20
      )
    end
  end
end
