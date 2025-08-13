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

      # Get existing partnerships
      existing_partnerships = @delivery_partner
        .lead_provider_delivery_partnerships
        .includes(active_lead_provider: %i[lead_provider contract_period])

      # Get all contract periods that have available lead providers (including those with existing partnerships)
      contract_periods_with_providers = ContractPeriod
        .joins(:active_lead_providers)
        .distinct
        .most_recent_first

      @contract_period_partnerships = contract_periods_with_providers.map do |contract_period|
        partnerships = existing_partnerships.select { |p| p.contract_period.year == contract_period.year }
        { contract_period:, partnerships: }
      end
    end
  end
end
