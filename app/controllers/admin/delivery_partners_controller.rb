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

    def edit
      @delivery_partner = DeliveryPartner.find(params[:id])
      @year = params[:year]
      @contract_period = ContractPeriod.find_by(year: @year)

      if @contract_period.blank?
        redirect_to admin_delivery_partner_path(@delivery_partner, page: params[:page], q: params[:q]),
                    alert: "Contract period for year #{@year} not found"
        return
      end

      @page = params[:page]
      @q = params[:q]

      @current_partnerships = @delivery_partner
        .lead_provider_delivery_partnerships
        .for_contract_period(@contract_period)

      @available_lead_providers = ActiveLeadProvider
        .available_for_delivery_partner(@delivery_partner, @contract_period)
    end

    def update
      Admin::DeliveryPartners::AddLeadProviders.new(
        delivery_partner_id: params[:id],
        year: params[:year],
        lead_provider_ids: params[:lead_provider_ids],
        author: current_user
      ).call

      redirect_to admin_delivery_partner_path(params[:id], page: params[:page], q: params[:q]),
                  alert: "Lead provider partners updated"
    rescue Admin::DeliveryPartners::AddLeadProviders::NoLeadProvidersSelectedError => e
      redirect_to edit_admin_delivery_partner_path(params[:id], year: params[:year], page: params[:page], q: params[:q]),
                  notice: e.message
    rescue Admin::DeliveryPartners::AddLeadProviders::ValidationError => e
      redirect_to admin_delivery_partner_path(params[:id], page: params[:page], q: params[:q]),
                  notice: e.message
    end
  end
end
