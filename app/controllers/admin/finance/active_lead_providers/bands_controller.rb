module Admin::Finance::ActiveLeadProviders
  class BandsController < Admin::Finance::BaseController
    layout "full"

    before_action :set_active_lead_provider
    before_action :set_band, only: %i[update show]

    def index
      @breadcrumbs = {
        "Finance" => admin_finance_path,
        "Contract periods" => admin_contract_periods_path,
        @active_lead_provider.contract_period_year.to_s => admin_contract_period_path(@active_lead_provider.contract_period),
        @active_lead_provider.lead_provider_name => admin_contract_period_active_lead_providers_path(@active_lead_provider.contract_period),
      }
      @bands = @active_lead_provider.bands
    end

    def new
    end

    def create
    end

    def edit
    end

    def update
    end

    def show
      @breadcrumbs = {
        "Finance" => admin_finance_path,
        "Contract periods" => admin_contract_periods_path,
        @active_lead_provider.contract_period_year.to_s => admin_contract_period_path(@active_lead_provider.contract_period),
        @active_lead_provider.lead_provider_name => admin_contract_period_active_lead_providers_path(@active_lead_provider.contract_period),
        friendly_band_name => admin_contract_period_active_lead_provider_contracts_path(@active_lead_provider.contract_period, @active_lead_provider),
      }
    end

    def delete
    end

  private

    def set_active_lead_provider
      @active_lead_provider = ActiveLeadProvider
        .includes(:contract_period, :lead_provider)
        .find(params.expect(:active_lead_provider_id))
    end

    def set_contract
      @contract = @active_lead_provider.contracts
        .includes(:statements, :flat_rate_fee_structure, banded_fee_structure: :band_terms)
        .find(params.expect(:id))
    end

    def bands_can_be_added?
      # rules here
      true
    end

    helper_method :bands_can_be_added?
  end
end
