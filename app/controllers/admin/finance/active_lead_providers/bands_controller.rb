module Admin::Finance::ActiveLeadProviders
  class BandsController < Admin::Finance::BaseController
    before_action :set_active_lead_provider
    before_action :set_band, only: %i[edit update delete]
    before_action :redirect_if_contracted_or_inside_contract_period, only: %i[create delete]

    def index
      set_breadcrumbs
      @bands = @active_lead_provider.bands
    end

    def new
      set_breadcrumbs
      @band = @active_lead_provider.bands.new
    end

    def create
      @band = @active_lead_provider.bands.new(band_params)

      if @band.valid?
        @band.save!
        redirect_to admin_contract_period_active_lead_provider_bands_path(contract_period, @active_lead_provider), notice: "#{label_for(band: @band)} added"
      else
        set_breadcrumbs
        render :new, status: :unprocessable_content
      end
    end

    def edit
      set_breadcrumbs(label_for(band: @band) => "#")
    end

    def update
      @band.assign_attributes(band_params)
      if @band.valid?
        @band.save!
        redirect_to admin_contract_period_active_lead_provider_bands_path(@active_lead_provider), notice: "Band updated"
      else
        set_breadcrumbs(description_for(@band) => "#")
        render :edit
      end
    end

    def delete
      if deletable?(band: @band)
        label = label_for(band: @band)
        bands_service.delete!(band: @band)
        redirect_to admin_contract_period_active_lead_provider_bands_path(@active_lead_provider), notice: "#{label} deleted"
      else
        redirect_to admin_contract_period_active_lead_provider_bands_path(@active_lead_provider), notice: "This band cannot be deleted"
      end
    end

  private

    def set_active_lead_provider
      @active_lead_provider = ActiveLeadProvider
        .includes(:contract_period, :lead_provider)
        .find(params.expect(:active_lead_provider_id))
    end

    def set_band
      @band = @active_lead_provider.bands
        .includes(:band_terms)
        .find(params.expect(:id))
    end

    def set_breadcrumbs(extras = {})
      @breadcrumbs = {
        "Finance" => admin_finance_path,
        "Contract periods" => admin_contract_periods_path,
        @active_lead_provider.contract_period_year.to_s => admin_contract_period_path(contract_period),
        @active_lead_provider.lead_provider_name => admin_contract_period_active_lead_providers_path(contract_period, @active_lead_provider),
      }.merge(extras)
    end

    def band_params
      params.expect(active_lead_provider_band: [:capacity])
    end

    def contract_period
      @contract_period ||= @active_lead_provider.contract_period
    end

    def editable?(band:)
      bands_service.editable?(band:)
    end

    def deletable?(band:)
      bands_service.deletable_band?(band:)
    end

    def label_for(band:)
      bands_service.label_for(band:)
    end

    def capacity_description_for(band:)
      bands_service.capacity_description_for(band:)
    end

    def bands_can_be_added?
      bands_service.bands_can_be_added?
    end

    def bands_can_be_deleted?
      bands_service.bands_can_be_deleted?
    end

    def bands_service
      @bands_service ||= Admin::Finance::Bands.new(active_lead_provider: @active_lead_provider)
    end

    def redirect_if_contracted_or_inside_contract_period
      unless bands_service.bands_can_be_added?
        redirect_to admin_contract_period_active_lead_provider_bands_path(contract_period, @active_lead_provider),
                    flash: {
                      error: "Bands cannot be added or removed once contracts have been added or the contract period has started"
                    }
      end
    end

    helper_method :bands_can_be_added?, :bands_can_be_deleted?, :editable?, :deletable?, :label_for, :capacity_description_for
  end
end
