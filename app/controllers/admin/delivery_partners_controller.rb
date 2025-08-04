module Admin
  class DeliveryPartnersController < AdminController
    include Pagy::Backend

    layout "full"

    def index
      @breadcrumbs = {
        "Organisations" => admin_organisations_path,
        "Delivery partners" => nil,
      }
      @pagy, @delivery_partners = pagy(::DeliveryPartners::Search.new(params[:q]).search)
    end

    def show
      @delivery_partner = DeliveryPartner.find(params[:id])
      @page = params[:page]
      @q = params[:q]
      @lead_provider_partnerships = @delivery_partner
        .lead_provider_delivery_partnerships
        .includes(active_lead_provider: %i[lead_provider contract_period])
        .merge(ContractPeriod.most_recent_first)
    end
  end
end
