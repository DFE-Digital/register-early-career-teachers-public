module Admin::Finance::ActiveLeadProviders
  class ContractsController < Admin::Finance::BaseController
    layout "full"

    before_action :set_active_lead_provider
    before_action :set_contract, only: %i[show]

    def index
      @breadcrumbs = {
        "Finance" => admin_finance_path,
        "Contract periods" => admin_contract_periods_path,
        @active_lead_provider.contract_period_year.to_s => admin_contract_period_path(@active_lead_provider.contract_period),
        @active_lead_provider.lead_provider_name => admin_contract_period_active_lead_providers_path(@active_lead_provider.contract_period),
      }
      @contracts = @active_lead_provider.contracts.includes(:statements).order(:created_at)
    end

    def show
      @breadcrumbs = {
        "Finance" => admin_finance_path,
        "Contract periods" => admin_contract_periods_path,
        @active_lead_provider.contract_period_year.to_s => admin_contract_period_path(@active_lead_provider.contract_period),
        @active_lead_provider.lead_provider_name => admin_contract_period_active_lead_providers_path(@active_lead_provider.contract_period),
        "Contracts" => admin_contract_period_active_lead_provider_contracts_path(@active_lead_provider.contract_period, @active_lead_provider),
      }
    end

  private

    def set_active_lead_provider
      @active_lead_provider = ActiveLeadProvider
        .includes(:contract_period, :lead_provider)
        .find(params.expect(:active_lead_provider_id))
    end

    def set_contract
      @contract = @active_lead_provider.contracts
        .includes(:statements, :flat_rate_fee_structure, banded_fee_structure: :bands)
        .find(params.expect(:id))
    end
  end
end
