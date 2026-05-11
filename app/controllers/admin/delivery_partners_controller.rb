module Admin
  class DeliveryPartnersController < AdminController
    include Pagy::Backend

    layout "full"
    before_action :set_delivery_partner, only: %i[show edit update]
    before_action :assign_backlink_params, only: %i[index show edit update new create]

    def index
      @breadcrumbs = {
        "Organisations" => admin_organisations_path,
        "Delivery partners" => nil,
      }
      page = params[:page].presence
      @pagy, @delivery_partners = pagy(::DeliveryPartners::Search.new(params[:q]).search, page:)
    end

    def show
      @breadcrumbs = {
        "Organisations" => admin_organisations_path,
        "Delivery partners" => admin_delivery_partners_path(page: @page, q: @q),
        @delivery_partner.name => nil
      }

      existing_partnerships = @delivery_partner
        .lead_provider_delivery_partnerships
        .includes(active_lead_provider: %i[lead_provider contract_period])

      contract_periods_with_providers = ContractPeriod
        .joins(:active_lead_providers)
        .distinct
        .most_recent_first

      @contract_period_partnerships = contract_periods_with_providers.map do |contract_period|
        partnerships = existing_partnerships.select { |p| p.contract_period.year == contract_period.year }
        { contract_period:, partnerships: }
      end
    end

    def new
      @breadcrumbs = new_delivery_partner_breadcrumbs
      @delivery_partner = DeliveryPartner.new
    end

    def create
      @delivery_partner = DeliveryPartner.new(name: params.dig(:delivery_partner, :name))

      if @delivery_partner.valid?
        delivery_partner = Admin::DeliveryPartners::Create.new(name: @delivery_partner.name, author: current_user).create!
        redirect_to admin_delivery_partner_path(delivery_partner, page: @page, q: @q),
                    alert: "Delivery partner added"
      else
        @breadcrumbs = new_delivery_partner_breadcrumbs
        render :new, status: :unprocessable_content
      end
    end

    def edit
      @breadcrumbs = {
        "Organisations" => admin_organisations_path,
        "Delivery partners" => admin_delivery_partners_path(page: @page, q: @q),
        @delivery_partner.name => admin_delivery_partner_path(@delivery_partner, page: @page, q: @s),
        "Change delivery partner name" => nil
      }
    end

    def update
      change_name_service.rename!

      redirect_to admin_delivery_partner_path(@delivery_partner, page: @page, q: @q),
                  alert: "Delivery partner name changed"
    rescue ActiveRecord::RecordInvalid
      render :edit, status: :unprocessable_content
    end

  private

    def set_delivery_partner
      @delivery_partner = DeliveryPartner.find(params[:id])
    end

    def assign_backlink_params
      @page = params[:page]
      @q    = params[:q]
    end

    def new_delivery_partner_breadcrumbs
      {
        "Organisations" => admin_organisations_path,
        "Delivery partners" => admin_delivery_partners_path(page: @page, q: @q),
        "Add a new delivery partner" => nil,
      }
    end

    def change_name_service
      Admin::DeliveryPartners::ChangeName.new(
        delivery_partner: @delivery_partner,
        proposed_name: params.dig(:delivery_partner, :name),
        author: current_user
      )
    end
  end
end
