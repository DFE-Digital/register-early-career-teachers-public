module Admin::Finance::ActiveLeadProviders
  class BandsController < Admin::Finance::BaseController
    include BandsHelper

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
      @band = Admin::Finance::Bands::Create.new(author: current_user, active_lead_provider: @active_lead_provider, capacity: band_params[:capacity])

      redirect_to bands_path, notice: "#{label_for(band: @band)} added"
    rescue ActiveRecord::RecordInvalid => e
      @band = e.record
      set_breadcrumbs
      render :new, status: :unprocessable_content
    end

    def edit
      set_breadcrumbs(label_for(band: @band) => "#")
    end

    def update
      Admin::Finance::Bands::Update.new(
        author: current_user,
        band: @band,
        capacity: band_params[:capacity]
      ).call

      redirect_to bands_path, notice: "Band updated"
    rescue ActiveRecord::RecordInvalid
      set_breadcrumbs(label_for(band: @band) => "#")
      render :edit, status: :unprocessable_content
    end

    def delete
      label = label_for(band: @band)
      Admin::Finance::Bands::Destroy.new(author: current_user, band: @band).call

      redirect_to bands_path, notice: "#{label} deleted"
    rescue Admin::Finance::Bands::Destroy::DeletionError => e
      redirect_to bands_path, flash: { error: e.message }
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
        @active_lead_provider.lead_provider_name => bands_path,
      }.merge(extras)
    end

    def band_params
      params.expect(active_lead_provider_band: [:capacity])
    end

    def contract_period
      @contract_period ||= @active_lead_provider.contract_period
    end

    def redirect_if_contracted_or_inside_contract_period
      unless @active_lead_provider.bands_can_be_added_and_removed?
        redirect_to admin_contract_period_active_lead_provider_bands_path(contract_period, @active_lead_provider),
                    flash: {
                      error: "Bands cannot be added or removed once contracts have been added or the contract period has started"
                    }
      end
    end

    def band_path(band)
      admin_contract_period_active_lead_provider_band_path(contract_period, @active_lead_provider, band)
    end

    def bands_path
      admin_contract_period_active_lead_provider_bands_path(contract_period, @active_lead_provider)
    end
  end
end
