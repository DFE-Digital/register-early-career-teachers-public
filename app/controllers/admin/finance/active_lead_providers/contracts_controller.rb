module Admin::Finance::ActiveLeadProviders
  class ContractsController < Admin::Finance::BaseController
    layout "full"

    before_action :set_active_lead_provider

    def index
      @breadcrumbs = {
        "Finance" => admin_finance_path,
        "Contract periods" => admin_contract_periods_path,
        @active_lead_provider.contract_period_year.to_s => admin_contract_period_path(@active_lead_provider.contract_period),
        @active_lead_provider.lead_provider_name => admin_contract_period_active_lead_providers_path(@active_lead_provider.contract_period),
      }
      @contracts = @active_lead_provider.contracts.includes(:flat_rate_fee_structure, banded_fee_structure: :bands)
    end

  private

    def set_active_lead_provider
      @active_lead_provider = ActiveLeadProvider
        .includes(:contract_period, :lead_provider)
        .find(params.expect(:active_lead_provider_id))
    end
  end
end
